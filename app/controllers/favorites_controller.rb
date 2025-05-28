class FavoritesController < ApplicationController
  before_action :require_login

  def create
    post = Post.find(params[:post_id])
    current_user.favorites.create(post: post)
    redirect_to request.referer || root_path
  end

  def destroy
    post = Post.find(params[:post_id])
    favorite = current_user.favorites.find_by(post_id: post.id)
    favorite&.destroy
    redirect_to request.referer || root_path
  end
end
