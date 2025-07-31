class PostsController < ApplicationController
  before_action :set_post, only: [ :show, :edit, :update, :destroy, :remove_image ]

  def index
    @q = Post.ransack(params[:q])
    @posts = @q.result.includes(:shop).latest_unique_by_shop_and_location.page(params[:page]).per(10)

    @prefectures = Prefecture.all

    if params.dig(:q, :shop_location_prefecture_id_eq).present?
      prefecture_id = params[:q][:shop_location_prefecture_id_eq]
      city_ids = Location.where(prefecture_id: prefecture_id).pluck(:city_id).uniq
      @cities = City.where(id: city_ids).order(:name)
    else
      @cities = City.none
    end
  end

  def new
    @post = Post.new
    load_collections
  end

  def cities
    if params[:prefecture_id].present?
      cities = City.where(prefecture_id: params[:prefecture_id]).order(:name)
    else
      cities = []
    end
    render json: { data: cities.map { |city| { id: city.id, name: city.name } } }
  end

  def create
    prefecture_id = params[:post][:prefecture_id]
    city_id       = params[:post][:city_id]

    if prefecture_id.to_i == 0 || city_id.to_i == 0
      load_collections
      flash.now[:danger] = t("defaults.flash_message.form_confirm", item: t("helpers.label.post.prefecture_city"))
      @post = Post.new(post_params)
      render :new, status: :unprocessable_entity and return
    end

    location = Location.find_or_create_by(prefecture_id: prefecture_id, city_id: city_id)

    shop_name = params[:post][:shop_name].to_s.strip
    if shop_name.blank?
      load_collections
      flash.now[:danger] = t("defaults.flash_message.form_confirm", item: t("helpers.label.post.shop_name"))
      render :new, status: :unprocessable_entity and return
    end

    shop = Shop.find_or_initialize_by(name: shop_name)
    shop.location = location
    shop.save!

    @post = current_user.posts.build(post_params.merge(shop_id: shop.id))

    if @post.save
      visit = Visit.find_or_initialize_by(user: current_user, shop: shop)
      visit = Visit.find_or_initialize_by(user: current_user, shop: shop)
      visit.count = visit.count.to_i + 1
      visit.save!

      redirect_to posts_path, notice: t("defaults.flash_message.created", item: Post.model_name.human)
    else
      Rails.logger.debug @post.errors.full_messages
      load_collections
      flash.now[:danger] = t("defaults.flash_message.not_created", item: Post.model_name.human)
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def edit
    load_collections
    @prefectures = Prefecture.order(:name)

    if @post.shop&.location&.prefecture
      prefecture = @post.shop.location.prefecture
      @cities = prefecture.locations.includes(:city).map(&:city).uniq.sort_by(&:name)
    else
      @cities = []
    end
  end

  def update
    prefecture_id = params[:post][:prefecture_id]
    city_id       = params[:post][:city_id]

    if prefecture_id.to_i == 0 || city_id.to_i == 0
      load_collections
      @prefectures = Prefecture.order(:name)
      if prefecture_id.present?
        prefecture = Prefecture.find_by(id: prefecture_id)
        @cities = prefecture ? prefecture.locations.includes(:city).map(&:city).uniq.sort_by(&:name) : []
      else
        @cities = []
      end

      flash.now[:danger] = t("defaults.flash_message.form_confirm", item: t("helpers.label.post.prefecture_city"))
      render :edit, status: :unprocessable_entity and return
    end

    location = Location.find_or_create_by(prefecture_id: prefecture_id, city_id: city_id)

    shop_name = params[:post][:shop_name].to_s.strip
    if shop_name.blank?
      load_collections
      @prefectures = Prefecture.order(:name)
      if prefecture_id.present?
        prefecture = Prefecture.find_by(id: prefecture_id)
        @cities = prefecture ? prefecture.locations.includes(:city).map(&:city).uniq.sort_by(&:name) : []
      else
        @cities = []
      end

      flash.now[:danger] = t("defaults.flash_message.form_confirm", item: t("helpers.label.post.shop_name"))
      render :edit, status: :unprocessable_entity and return
    end

    shop = Shop.find_or_initialize_by(name: shop_name)
    shop.location = location
    shop.save!

    if @post.update(post_params.merge(shop_id: shop.id))
      if params[:post][:remove_post_image] == "1"
        @post.remove_post_image!
        @post.save
      end

      redirect_to post_path(@post), notice: t("defaults.flash_message.updated", item: Post.model_name.human)
    else
      load_collections
      @prefectures = Prefecture.order(:name)
      if prefecture_id.present?
        prefecture = Prefecture.find_by(id: prefecture_id)
        @cities = prefecture ? prefecture.locations.includes(:city).map(&:city).uniq.sort_by(&:name) : []
      else
        @cities = []
      end
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

  def history
    @post = current_user.posts.find_by(id: params[:id])
    unless @post
      redirect_to posts_path, alert: t("defaults.flash_message.not_authorized") and return
    end

    shop_id = @post.shop_id
    location_id = @post.shop.location_id

    @history_posts = Post.same_shop_and_location(shop_id, location_id)
                       .includes(:category, :feeling, :companion, :visit_reason)

    visits = Visit.where(user: current_user, shop_id: [ @post.shop_id ])  # もしくは history 投稿すべての shop_id を収集
    @visits_by_shop = visits.index_by(&:shop_id)
  end

  private

  def post_params
    params.require(:post).permit(
      :visit_date, :category_id, :companion_id, :feeling_id, :visit_reason_id, :body,
      :post_image, :post_image_cache, :remove_post_image
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
    unless @post
      redirect_to posts_path, alert: t("defaults.flash_message.not_authorized")
    end
  end
end
