class ResourcesController < ApplicationController
  include Derivativo::RequestTokenAuthentication

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  # GET /resource
  # API Info
  def index
    render json: {
      "api_version" => "1.0.0"
    }
  end

  # PUT /resources/:id
  def update
    id = params[:id]
    unless (status = authenticate_request_token) == :ok
      render status: status, json: {"error" => "Invalid credentials"}
      return
    end
    begin
      res = DerivativoResource.new(id)
      res.generate_cache(DERIVATIVO[:queue_long_jobs], self)
    rescue Derivativo::Exceptions::ResourceNotFound
      render status: :not_found, json: { "error" => "Resource not found" }
      return
    end
    render status: status, json: { "success" => true }
  end

  # DELETE /resources/:id
  def destroy
    id = params[:id]
    unless (status = authenticate_request_token) == :ok
      render status: status, json: {"error" => "Invalid credentials"}
      return
    end
    begin
      DerivativoResource.new(id).clear_cache
    rescue Derivativo::Exceptions::ResourceNotFound
      render status: :not_found, json: { "error" => "Resource not found" }
      return
    end
    render status: status, json: { "success" => true }
  end

  # DELETE /resources/:id/destroy_cachable_properties
  def destroy_cachable_properties
    id = params[:id]
    unless (status = authenticate_request_token) == :ok
      render status: status, json: {"error" => "Invalid credentials"}
      return
    end
    begin
      DerivativoResource.new(id).clear_cachable_properties
    rescue Derivativo::Exceptions::ResourceNotFound
      render status: :not_found, json: { "error" => "Resource not found" }
      return
    end
    render status: status, json: { "success" => true }
  end
end
