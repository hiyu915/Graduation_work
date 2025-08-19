class PostsController < ApplicationController
  before_action :set_post, only: [:show, :edit, :update, :destroy, :remove_image, :history]

  # 投稿一覧
  def index
    @q = Post.ransack(params[:q])
    sort_column = params[:sort] || "visit_date"
    sort_direction = %w[asc desc].include?(params[:direction].to_s.downcase) ? params[:direction].to_s.downcase : "desc"

    posts = @q.result.includes(:shop, :category, :companion, :feeling, :visit_reason)

    # リピート（お気に入り）絞り込み
    if params[:repeat].present? && current_user
      favorite_post_ids = current_user.favorites.pluck(:post_id)
      posts = posts.where(id: favorite_post_ids)
    end

    # 店舗ごとの最新投稿のみ取得
    posts = posts.latest_unique_by_shop_and_location

    # visit_count でのソート（ユーザーごと）
    if sort_column == "visit_count" && current_user
      visit_counts = Visit.where(user_id: current_user.id)
                          .group(:shop_id)
                          .select("shop_id, SUM(count) AS visit_count_sum")

      posts = posts
                .joins("LEFT JOIN (#{visit_counts.to_sql}) AS visit_counts ON visit_counts.shop_id = posts.shop_id")
                .select("posts.*, COALESCE(visit_counts.visit_count_sum, 0) AS visit_count")
                .order(Arel.sql("visit_count #{sort_direction.upcase}, posts.visit_date DESC"))
    else
      order_clause = sort_column == "visit_date" ? "posts.visit_date #{sort_direction.upcase}" : "posts.visit_date DESC"
      posts = posts.order(order_clause)
    end

    @posts = posts.page(params[:page]).per(10)

    # 現在ページの投稿に紐づく訪問情報を取得
    shop_ids = @posts.map(&:shop_id)
    @visits_by_shop = Visit.where(user: current_user, shop_id: shop_ids).index_by(&:shop_id)

    # 都道府県・市の選択肢
    @prefectures = Prefecture.all
    if params.dig(:q, :shop_location_prefecture_id_eq).present?
      prefecture_id = params[:q][:shop_location_prefecture_id_eq]
      city_ids = Location.where(prefecture_id: prefecture_id).pluck(:city_id).uniq
      @cities = City.where(id: city_ids).order(:name)
    else
      @cities = City.none
    end

    respond_to do |format|
      format.html
      format.turbo_stream if turbo_frame_request?
    end
  end

  # 投稿履歴（同店舗）
  def history
    shop_id = @post.shop_id

    posts_scope = Post.where(shop_id: shop_id)
                      .includes(:category, :feeling, :companion, :visit_reason)

    @q = posts_scope.ransack(params[:q])
    posts = @q.result

    if params[:repeat].present? && current_user
      favorite_post_ids = current_user.favorites.pluck(:post_id)
      posts = posts.where(id: favorite_post_ids)
    end

    # ソート
    sort_column = params[:sort] || "visit_date"
    sort_direction = %w[asc desc].include?(params[:direction].to_s.downcase) ? params[:direction].to_s.downcase : "desc"
    posts = posts.order("posts.visit_date #{sort_direction.upcase}")

    @history_posts = posts.page(params[:page]).per(10)
    @visits_by_shop = Visit.where(user: current_user, shop_id: shop_id).index_by(&:shop_id)

    respond_to do |format|
      format.html { render :history, locals: { visits_by_shop: @visits_by_shop } }
      format.turbo_stream
    end
  end

  # 新規投稿フォーム
  def new
    @post = Post.new
    load_collections
  end

  # 投稿作成
  def create
    location, shop = build_location_and_shop
    return unless location && shop

    @post = current_user.posts.build(post_params.merge(shop_id: shop.id))

    if @post.save
      update_visit_count(shop)
      redirect_to posts_path, notice: t("defaults.flash_message.created", item: Post.model_name.human)
    else
      load_collections
      flash.now[:danger] = t("defaults.flash_message.not_created", item: Post.model_name.human)
      render :new, status: :unprocessable_entity
    end
  end

  # 投稿詳細
  def show; end

  # 編集フォーム
  def edit
    load_collections
    @prefectures = Prefecture.order(:name)
    @cities = @post.shop&.location ? @post.shop.location.prefecture.locations.includes(:city).map(&:city).uniq.sort_by(&:name) : []
  end

  # 投稿更新
  def update
    location, shop = build_location_and_shop
    return unless location && shop

    if @post.update(post_params.merge(shop_id: shop.id))
      remove_image_if_requested
      redirect_to post_path(@post), notice: t("defaults.flash_message.updated", item: Post.model_name.human)
    else
      load_collections
      flash.now[:danger] = t("defaults.flash_message.not_updated", item: Post.model_name.human)
      render :edit, status: :unprocessable_entity
    end
  end

  # 投稿削除
  def destroy
    shop = @post.shop
    ActiveRecord::Base.transaction do
      @post.destroy!
      visit = Visit.find_by(user: current_user, shop: shop)
      if visit
        visit.count -= 1
        visit.count <= 0 ? visit.destroy! : visit.save!
      end
    end
    redirect_to posts_path, success: t("defaults.flash_message.deleted", item: Post.model_name.human)
  end

  # 画像削除
  def remove_image
    @post.remove_post_image!
    @post.save
    redirect_to post_path(@post), notice: t("defaults.flash_message.image_removed")
  end

  private

  # Strong Parameters
  def post_params
    params.require(:post).permit(
      :visit_date, :category_id, :companion_id, :feeling_id, :visit_reason_id, :body,
      :post_image, :post_image_cache, :remove_post_image
    )
  end

  # 各種コレクションをロード
  def load_collections
    @categories    = Category.order(:name)
    @shops         = Shop.order(:name)
    @feelings      = Feeling.order(:name)
    @companions    = Companion.order(:name)
    @visit_reasons = VisitReason.order(:name)
    @prefectures   = Prefecture.order(:name)
  end

  # 投稿取得
  def set_post
    @post = current_user.posts.find_by(id: params[:id])
    redirect_to posts_path, alert: t("defaults.flash_message.not_authorized") unless @post
  end

  # 店舗・場所の作成/取得
  def build_location_and_shop
    prefecture_id = params[:post][:prefecture_id].to_i
    city_id       = params[:post][:city_id].to_i
    shop_name     = params[:post][:shop_name].to_s.strip

    if prefecture_id.zero? || city_id.zero?
      load_collections
      flash.now[:danger] = t("defaults.flash_message.form_confirm", item: t("helpers.label.post.prefecture_city"))
      render params[:action] == "create" ? :new : :edit, status: :unprocessable_entity
      return
    end

    if shop_name.blank?
      load_collections
      flash.now[:danger] = t("defaults.flash_message.form_confirm", item: t("helpers.label.post.shop_name"))
      render params[:action] == "create" ? :new : :edit, status: :unprocessable_entity
      return
    end

    location = Location.find_or_create_by(prefecture_id: prefecture_id, city_id: city_id)
    shop = Shop.find_or_initialize_by(name: shop_name)
    shop.location = location
    shop.save!

    [location, shop]
  end

  # 訪問回数更新
  def update_visit_count(shop)
    visit = Visit.find_or_initialize_by(user: current_user, shop: shop)
    visit.count = visit.count.to_i + 1
    visit.save!
  end

  # 画像削除チェック
  def remove_image_if_requested
    if params[:post][:remove_post_image] == "1"
      @post.remove_post_image!
      @post.save
    end
  end
end
