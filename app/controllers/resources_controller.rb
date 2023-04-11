# frozen_string_literal: true

class ResourcesController < ApplicationController
  include Derivativo::RequestTokenAuthentication

  before_action :authenticate_request_token, :set_resource

  # Since this is an API, we won't do a CSRF check.
  # See: https://api.rubyonrails.org/classes/ActionController/RequestForgeryProtection/ClassMethods.html#method-i-skip_forgery_protection
  skip_forgery_protection

  # PATCH /resources/:id
  def update
    render json: { success: true }
  end

  # DELETE /resources/:id
  # This endpoint supports the Hyacinth use case of rotating an image and wanting to regenerate
  # derivatives for the rotated image.
  def destroy
    @resource.destroy_base_and_iiif_cache!
    Imogen.clear_vips_cache_mem
    render json: { success: true }
  end

  # DELETE /resources/:id/destroy_cachable_properties
  def destroy_cachable_properties
    # TODO: Decide what this actually means in Derivativo 1.5.  Probably just clearing placeholder?
    render json: { success: true }
  end

  private

  def set_resource
    @resource = Resource.new(params[:id])
  end
end
