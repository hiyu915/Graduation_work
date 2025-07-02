class AccountsController < ApplicationController
  before_action :require_login

  def show
  end

  def destroy
    current_user.destroy
    logout
    redirect_to root_path, notice: t("accounts.destroy.success")
  end
end
