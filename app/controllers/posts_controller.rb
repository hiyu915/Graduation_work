class PostsController < ApplicationController
  before_action :set_post, only: [ :show, :edit, :update, :destroy, :remove_image, :history ]

  # 投稿一覧
  def index
    @q = Post.ransack(params[:q])
    sort_column = params[:sort] || "visit_date"
    sort_direction = %w[asc desc].include?(params[:direction].to_s.downcase) ? params[:direction].to_s.downcase : "desc"

    posts = @q.result.includes(:shop, :category, :companion, :feeling, :visit_reason)
    posts = posts.where(user: current_user) if current_user

    if params[:repeat].present? && current_user
      favorite_post_ids = current_user.favorites.pluck(:post_id)
      posts = posts.where(id: favorite_post_ids)
    end

    posts = posts.latest_unique_by_shop_and_location

    if sort_column == "visit_count" && current_user
      visit_counts = Visit.where(user_id: current_user.id)
                          .group(:shop_id)
                          .select("shop_id, SUM(count) AS visit_count_sum")

      posts = posts
                .joins("LEFT JOIN (#{visit_counts.to_sql}) AS visit_counts ON visit_counts.shop_id = posts.shop_id")
                .select("posts.*, COALESCE(visit_counts.visit_count_sum, 0) AS visit_count")
                .order("visit_count #{sort_direction.upcase}, posts.visit_date DESC")
    else
      order_clause = sort_column == "visit_date" ? "posts.visit_date #{sort_direction.upcase}" : "posts.visit_date DESC"
      posts = posts.order(order_clause)
    end

    @posts = posts.page(params[:page]).per(10)
    shop_ids = @posts.map(&:shop_id)
    @visits_by_shop = Visit.where(user: current_user, shop_id: shop_ids).index_by(&:shop_id)

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

  def cities
    if params[:prefecture_id].present?
      cities = City.where(prefecture_id: params[:prefecture_id]).order(:name)
    else
      cities = []
    end
    render json: { data: cities.map { |city| { id: city.id, name: city.name } } }
  end

  # マップ表示
  def map
   posts = current_user.posts
                      .includes(shop: { location: [ :prefecture, :city ] })
                      .where.not(locations: { latitude: nil, longitude: nil })
                      .order(visit_date: :desc)

    @location_groups = posts.group_by { |p| p.shop.location }
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

  def new
    @post = Post.new
    load_collections
  end

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

  def show; end

  def edit
    load_collections
    @prefectures = Prefecture.order(:name)
    @cities = @post.shop&.location ? @post.shop.location.prefecture.locations.includes(:city).map(&:city).uniq.sort_by(&:name) : []
  end

  def update
    location, shop = build_location_and_shop
    return unless location && shop

    old_shop = @post.shop

    if @post.update(post_params.merge(shop_id: shop.id))
      if old_shop != shop
        old_visit = Visit.find_by(user: current_user, shop: old_shop)
        if old_visit
          if old_visit.count.to_i > 1
            old_visit.decrement!(:count)
          else
            old_visit.destroy
          end
        end

        new_visit = Visit.find_or_initialize_by(user: current_user, shop: shop)
        new_visit.count = new_visit.count.to_i + 1
        new_visit.save!
      end

      remove_image_if_requested
      redirect_to post_path(@post), notice: t("defaults.flash_message.updated", item: Post.model_name.human)
    else
      load_collections
      flash.now[:danger] = t("defaults.flash_message.not_updated", item: Post.model_name.human)
      render :edit, status: :unprocessable_entity
    end
  end

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

  def remove_image
    @post.remove_post_image!
    @post.save
    redirect_to post_path(@post), notice: t("defaults.flash_message.image_removed")
  end

  def calendar
    @posts = current_user.posts.where.not(visit_date: nil).includes(:shop)
  end

  def autocomplete
    @posts = Post.joins(:shop)
                .where(user: current_user)
                .where("shops.name ILIKE ?", "%#{params[:q]}%")
                .limit(10)

    respond_to do |format|
      format.js
    end
  end

  private

  def post_params
    params.require(:post).permit(
      :visit_date, :category_id, :companion_id, :feeling_id, :visit_reason_id, :body,
      :post_image, :post_image_cache, :remove_post_image, :shop_name
    )
  end

  def load_collections
    @categories    = Category.order(:name)
    @shops         = Shop.order(:name)
    @feelings      = Feeling.order(:name)
    @companions    = Companion.order(:name)
    @visit_reasons = VisitReason.order(:name)
    @prefectures   = Prefecture.order(:name)
  end

  def set_post
    @post = current_user.posts.find_by(id: params[:id])
    redirect_to posts_path, alert: t("defaults.flash_message.not_authorized") unless @post
  end

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

    location = Location.find_or_initialize_by(prefecture_id: prefecture_id, city_id: city_id)
    location.save! if location.new_record? || location.latitude.blank? || location.longitude.blank?

    shop = Shop.find_or_initialize_by(name: shop_name, location: location)
    shop.save! if shop.new_record?

    [ location, shop ]
  end

  def update_visit_count(shop)
    visit = Visit.find_or_initialize_by(user: current_user, shop: shop)
    visit.count = visit.count.to_i + 1
    visit.save!
  end

  def remove_image_if_requested
    if params[:post][:remove_post_image] == "1"
      @post.remove_post_image!
      @post.save
    end
  end
end
