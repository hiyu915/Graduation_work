class PostsController < ApplicationController
  before_action :set_post, only: [ :show, :edit, :update, :destroy ]

  def index
    @posts = Post.includes(:user, :category, :shop, :feeling, :companion, :visit_reason)
  end

  def new
    @post = Post.new
    load_collections
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
      redirect_to post_path(@post), success: t("defaults.flash_message.updated", item: Post.model_name.human)
    else
      Rails.logger.debug @post.errors.full_messages
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
    @post.destroy!
    redirect_to posts_path, success: t("defaults.flash_message.deleted", item: Post.model_name.human)
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
    @post = Post.find(params[:id])
  end
end