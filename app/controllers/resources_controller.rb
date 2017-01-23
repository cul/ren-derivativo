class ResourcesController < ApplicationController

  # GET /resource/publish
  # API Info
  def index
    render json: {
      "api_version" => "1.0.0"
    }
  end

  # PUT /resource/:id
  def update
    id = params[:id]
    unless (status = authenticate_publisher) == :ok
      render status: status, json: {"error" => "Invalid credentials"}
      return
    end
    begin
      res = DerivativoResource.new(id)
      res.generate_cache
    rescue Derivativo::Exceptions::ResourceNotFound
      render status: :not_found, json: { "error" => "Resource not found" }
      return
    end
    render status: status, json: { "success" => true }
  end

  # DELETE /resource/:id
  def destroy
    id = params[:id]
    unless (status = authenticate_publisher) == :ok
      render status: status, json: {"error" => "Invalid credentials"}
      return
    end
    begin
      res = DerivativoResource.new(id)
      res.clear_cache
    rescue Derivativo::Exceptions::ResourceNotFound
      render status: :not_found, json: { "error" => "Resource not found" }
      return
    end
    render status: status, json: { "success" => true }
  end
  
  private
  
  def authenticate_publisher
    status = :unauthorized
    authenticate_with_http_token do |token, other_options|
      status = (DERIVATIVO['remote_request_api_key'] == token) ? :ok : :forbidden
    end
    status
  end
  
end
