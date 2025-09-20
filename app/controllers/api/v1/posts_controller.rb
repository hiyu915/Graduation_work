class Api::V1::PostsController < ApplicationController
  def index
    posts = Post.all
    render json: {
      data: posts,
      status: "success"
    }
  end

  def create
    post = current_user.posts.build(post_params)
    if post.save
      render json: post, status: :ok
    else
      render json: post.errors, status: :unprocessable_entity
    end
  end

  def show
    post = Post.find(params[:id])
    render json: {
      data: post,
      status: "success"
    }
  rescue ActiveRecord::RecordNotFound
    render json: {
      error: "Post not found",
      status: "error"
    }, status: :not_found
  end

  def update
    post = current_user.posts.find(params[:id])

    if post.update(post_params)
      render json: {
        data: post,
        status: "success",
        message: "Post updated successfully"
      }, status: :ok
    else
      render json: {
        errors: post.errors,
        status: "error"
      }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: {
      error: "Post not found",
      status: "error"
    }, status: :not_found
  end

   def destroy
    post = current_user.posts.find(params[:id])

    if post.destroy
      render json: {
        status: "success",
        message: "Post deleted successfully"
      }, status: :ok
    else
      render json: {
        errors: post.errors,
        status: "error"
      }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: {
      error: "Post not found",
      status: "error"
    }, status: :not_found
  end

  private

  def post_params
    params.require(:post).permit(
      :shop_name,
      :body,
      :visit_date,
      :post_image,
      :visits_count,
      :category_id,
      :shop_id,
      :companion_id,
      :feeling_id,
      :visit_reason_id
    )
  end
end
