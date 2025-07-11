class UsersController < ApplicationController
  skip_before_action :require_login, only: %i[new create activate]
  before_action :require_login, only: %i[edit_email request_email_change confirm_email_change]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      @user.reload
      auto_login(@user)
      UserMailer.activation_needed_email(@user).deliver_now
      redirect_to root_path, success: t("users.activation.sent")
    else
      flash.now[:danger] = t("users.create.failure")
      render :new, status: :unprocessable_entity
    end
  end

  def activate
    @user = User.load_from_activation_token(params[:id])
    if @user&.activate!
      redirect_to posts_path, success: t("users.activation.success")
    else
      redirect_to root_path, danger: t("users.activation.failure")
    end
  end

  def edit_email
    @user = current_user
  end

  def request_email_change
    @user = current_user
    new_email = params[:user][:unconfirmed_email]

    if User.exists?(email: new_email)
      flash.now[:danger] = t("mail_address_reset.request.duplicate")
      render :edit_email, status: :unprocessable_entity
    else
      @user.generate_email_change_token!(new_email)
      UserMailer.email_change_verification(@user).deliver_now
      redirect_to root_path, success: t("mail_address_reset.request.success")
    end
  end

  def confirm_email_change
    user = User.find_by(email_change_token: params[:token])

    if user&.email_change_token_valid?(params[:token])
      user.confirm_email_change!
      redirect_to root_path, success: t("mail_address_reset.confirm.success")
    else
      redirect_to root_path, danger: t("mail_address_reset.confirm.failure")
    end
  end

  def account_info
    @user = current_user
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
