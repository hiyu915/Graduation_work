class OauthsController < ApplicationController
  skip_before_action :require_login

  def oauth
    login_at(auth_params[:provider])
  end

  def callback
    provider = auth_params[:provider]

    if (@user = login_from(provider))
      redirect_to root_path, notice: t("oauths.callback.success", provider: provider.titleize)
    else
      begin
        signup_and_login(provider)
        redirect_to root_path, notice: t("oauths.callback.success", provider: provider.titleize)
      rescue
        redirect_to root_path, alert: t("oauths.callback.failure", provider: provider.titleize)
      end
    end
  end

  private

  def auth_params
    params.permit(:code, :provider)
  end

  def signup_and_login(provider)
    @user = create_from(provider)
    reset_session
    auto_login(@user)
  end
end
