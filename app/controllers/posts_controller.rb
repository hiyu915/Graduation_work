class PostsController < ApplicationController
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

    location = Location.find_or_create_by(prefecture_id: prefecture_id, city_id: city_id)

    shop_name = params[:post][:shop_name].to_s.strip
    if shop_name.blank?
      load_collections
      flash.now[:danger] = "店舗名を入力してください"
      render :new, status: :unprocessable_entity and return
    end

    shop = Shop.find_or_initialize_by(name: shop_name)
    shop.location = location
    shop.save!

    @post = current_user.posts.build(post_params.merge(shop_id: shop.id))

    if @post.save
      redirect_to posts_path, success: t("defaults.flash_message.created", item: Post.model_name.human)
    else
      Rails.logger.debug @post.errors.full_messages
      load_collections
      flash.now[:danger] = t("defaults.flash_message.not_created", item: Post.model_name.human)
      render :new, status: :unprocessable_entity
    end
end

  private

  def post_params
    params.require(:post).permit(
      :visit_date, :category_id, :companion_id, :feeling_id, :visit_reason_id, :body,
      :post_image, :post_image_cache
    )
  end

  def load_collections
    @categories    = Category.order(:name)
    @shops         = Shop.order(:name)
    @feelings      = Feeling.order(:name)
    @companions    = Companion.order(:name)
    @visit_reasons = VisitReason.order(:name)
  end
end
