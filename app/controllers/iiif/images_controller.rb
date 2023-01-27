# frozen_string_literal: true

class Iiif::ImagesController < ApplicationController
  before_action :enable_cors, only: [:iiif_id, :info]

  # GET /iiif/2/:id
  def iiif_id
    # The id url route just redirects to info url route for that id
    redirect_to iiif_info_url(id: params[:id], format: :json, version: params[:version]), status: :found
  end

  # GET /iiif/2/:id/info.json
  def info
    render json: { success: true }
  end

  # GET /iiif/2/:id/:region/:size/:rotation/:quality.(:format)
  # e.g. /iiif/2/sample/full/full/0/default.png
  def raster
    render plain: 'raster'
  end

  private

  def enable_cors
    response.headers['Access-Control-Allow-Origin'] = '*'
  end
end
