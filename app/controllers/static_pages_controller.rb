class StaticPagesController < ApplicationController
  skip_before_action :require_login, only: %i[top help privacy news faq]

  def top; end
  def privacy; end
  def help; end
  def news; end
  def faq; end
end
