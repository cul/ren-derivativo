# frozen_string_literal: true

class ResourcesController < ApplicationController
  # PATCH /resources/:id
  def update
    render json: { success: true }
  end

  # DELETE /resources/:id
  def destroy
    render json: { success: true }
  end

  # DELETE /resources/:id/destroy_cachable_properties
  def destroy_cachable_properties
    render json: { success: true }
  end
end
