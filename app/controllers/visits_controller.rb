class VisitsController < ApplicationController
  before_action :require_login
  before_action :set_post

  def create
    @post.increment!(:visits_count)
    render json: { count: @post.visits_count }
  end

  def destroy
    if @post.visits_count > 0
      @post.decrement!(:visits_count)
    end
    render json: { count: @post.visits_count }
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Not authorized" }, status: :forbidden
  end
end
