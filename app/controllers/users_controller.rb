class UsersController < ApplicationController
  skip_before_action :require_login, only: %i[new create activate finish_oauth]
  before_action :require_login, only: %i[edit_email request_email_change confirm_email_change account_info]

  # 新規登録フォーム
  def new
    @user = User.new
  end

  # ユーザー作成
  def create
    @user = User.new(user_params)
    if @user.save
      @user.reload
      auto_login(@user)
      UserMailer.activation_needed_email(@user).deliver_later
      redirect_to root_path, success: t("users.activation.sent")
    else
      flash.now[:danger] = t("users.create.failure")
      render :new, status: :unprocessable_entity
    end
  end

  # メール認証リンク経由
  def activate
    @user = User.load_from_activation_token(params[:id])
    if @user&.activate!
      redirect_to posts_path, success: t("users.activation.success")
    else
      redirect_to root_path, danger: t("users.activation.failure")
    end
  end

  # メールアドレス再設定用フォーム（ログイン中ユーザー）
  def edit_email
    @user = current_user
  end

  # メールアドレス変更リクエスト
  def request_email_change
    @user = current_user
    new_email = params[:user][:unconfirmed_email]

    # 1. 空文字チェック
    if new_email.blank?
      flash.now[:danger] = "メールアドレスを入力してください"
      render :edit_email, status: :unprocessable_entity
      return
    end

    # 2. メール形式チェック
    unless valid_email_format?(new_email)
      flash.now[:danger] = "メールアドレスは不正な値です"
      render :edit_email, status: :unprocessable_entity
      return
    end

    # 3. 重複チェック
    if User.exists?(email: new_email)
      flash.now[:danger] = t("mail_address_reset.request.duplicate")
      render :edit_email, status: :unprocessable_entity
    else
      @user.generate_email_change_token!(new_email)
      UserMailer.email_change_verification(@user).deliver_later
      redirect_to root_path, success: t("mail_address_reset.request.success")
    end
  end

  # メールアドレス変更確認
  def confirm_email_change
    user = User.find_by(email_change_token: params[:token])

    if user&.email_change_token_valid?(params[:token])
      user.confirm_email_change!
      redirect_to root_path, success: t("mail_address_reset.confirm.success")
    else
      redirect_to root_path, danger: t("mail_address_reset.confirm.failure")
    end
  end

  # ユーザーアカウント情報
  def account_info
    @user = current_user
  end

  # --- OAuth でメール未取得時の処理 ---
  def finish_oauth
    data = session[:external_auth_data]

    unless data.present? && data[:provider].present? && data[:uid].present?
      redirect_to login_path, alert: "OAuth情報が見つかりません。再度ログインしてください。" and return
    end

    @user = User.new(email: params[:user][:email])
    @user.authentications.build(provider: data[:provider], uid: data[:uid])

    if @user.save
      reset_session
      auto_login(@user)
      session.delete(:external_auth_data)
      redirect_to root_path, notice: "#{data[:provider].to_s.titleize}でログインしました"
    else
      flash.now[:danger] = "ユーザー作成に失敗しました"
      render :edit_email_form, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end

  def valid_email_format?(email)
    # シンプルで効果的なメール形式チェック
    email.match?(/\A[^@\s]+@[^@\s]+\.[^@\s]+\z/)
  end
end
