class FavoritesController < ApplicationController
  before_action :require_login
  before_action :set_post
  
  def create
    current_user.favorites.create(post: @post)
    respond_to do |format|
      format.html { redirect_to request.referer || root_path }
      format.turbo_stream
    end
  end

  def destroy
    favorite = current_user.favorites.find_by(post_id: @post.id)
    favorite&.destroy
    respond_to do |format|
      format.html { redirect_to request.referer || root_path }
      format.turbo_stream
    end
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end
end
