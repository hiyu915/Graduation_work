class CitiesController < ApplicationController
  def index
    if params[:prefecture_id].present?
      @cities = City.where(prefecture_id: params[:prefecture_id])
    else
      @cities = City.all
    end

    respond_to do |format|
      format.json { render json: @cities.select(:id, :name) }
    end
  end
end
