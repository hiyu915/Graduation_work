class PagesController < ApplicationController
  skip_before_action :require_login, only: [:terms]

  def terms
  end
end
