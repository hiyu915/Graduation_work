class UserSessionsController < ApplicationController
  skip_before_action :require_login, only: %i[new create]

  def new
    @user = User.new  # この行を追加
  end

  def create
    # 両方のパラメータ形式に対応
    if params[:user].present?
      # ブラウザからの場合（ネストあり）
      email = params[:user][:email]
      password = params[:user][:password]
    else
      # テストからの場合（ネストなし）
      email = params[:email]
      password = params[:password]
    end

    @user = login(email, password)

    if @user
      redirect_to posts_path, success: t("user_sessions.create.success")
    else
      @user = User.new
      flash.now[:danger] = t("user_sessions.create.failure")
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    logout
    redirect_to root_path, success: t("user_sessions.destroy.success"), status: :see_other
  end
end
