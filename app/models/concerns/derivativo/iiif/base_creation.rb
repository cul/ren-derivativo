module Derivativo::Iiif::BaseCreation
  extend ActiveSupport::Concern
  
  def base_derivatives_complete?
		return false unless base_exists?
		return false unless featured_base_exists?
		return false if db_cache_record.derivative_generation_in_progress
		true
	end
  
  def queue_base_derivatives_if_not_exist
		Resque.enqueue_to(Cul::Repo::Cache::Queue::LOW, CreateBaseDerivativesJob, id, Time.now.to_s)
	end
  
  def create_base_derivatives_if_not_exist
		# Avoid duplicate base creation requests while base creation is in progress
    return if db_cache_record.derivative_generation_in_progress
    
    # Mark derivative generation as being in progress in the database
    db_cache_record.update(derivative_generation_in_progress: true)
    
    begin
			# Base derivatives for placeholder are based on specific app-supplied images
			if self.id.start_with?('placeholder:')
				placeholder_type = id.gsub('placeholder:', '')
				placeholder_src_file = File.join(Rails.root, 'app/assets/images/placeholders/dark', placeholder_type + '.png')
				unless File.exists?(placeholder_src_file)
					raise "Attempt to copy placeholder image into cache for #{self.id} failed because src file #{placeholder_src_file} was not found."
					return
				end
				placeholder_base_dst_file = base_cache_path(true)
				placeholder_featured_dst_file = featured_base_cache_path(true)
				FileUtils.cp(placeholder_src_file, placeholder_base_dst_file)
				FileUtils.cp(placeholder_src_file, placeholder_featured_dst_file)
				return
			end
	
			generic_resource = ActiveFedora::Base.find(self.id)
			
			# We only ever want to create base derivatives for rasterable GenericResources (like images or PDFs).
			# Serving up of representative images is handled elsewhere, by the IiifController, so we'll reject
			# anything here that isn't a rasterable GenericResource.
			unless is_rasterable_generic_resource?(generic_resource)
				if generic_resource.is_a?(GenericResource)
					Rails.logger.info "Skipped creation of base image derivatives for GenericResource #{self.id} because it is not of a known rasterable type (image, PDF, etc)."
				else
					Rails.logger.info "Skipped creation of base derivatives for #{generic_resource.class.name} #{self.id} because it is not a GenericResource."
				end
				return
			end
			
			unless File.exists?(base_cache_path = base_cache_path(true))
				generic_resource.with_ds_resource('content', (! DERIVATIVO['no_mount']) ) do |image_path|
					if is_generic_resource_image?(generic_resource)
						Imogen.with_image(image_path) do |img|
							# Create base image
							Rails.logger.debug 'Creating base image...'
							start_time = Time.now
							Imogen::Iiif.convert(img, base_cache_path, :png, {
								region: 'full',
								size: 'full',
								rotation: generic_resource.required_rotation_for_upright_display.to_s
							})
							Rails.logger.debug 'Created base image in ' + (Time.now-start_time).to_s + ' seconds'
						end
					elsif is_generic_resource_pdf?(generic_resource)
						Rails.logger.debug 'Creating base image from PDF...'
						start_time = Time.now
						
						# Using '[0]' at end of the filename to tell ImageMagick to only look at the first page.
						# MUCH faster than Magick::ImageList.new(image_path) or Magick::Image.read(image_path) for multi-page PDFs.
						pdf = Magick::Image.read(image_path + '[0]')
						
						pdf[0].write(base_cache_path)
						Rails.logger.debug 'Created base image from PDF in ' + (Time.now-start_time).to_s + ' seconds'
					end
				end
			end
			
			unless File.exists?(featured_base_cache_path = featured_base_cache_path(true))
				# Create featured base image from base image
				Imogen.with_image(base_cache_path) do |img|
					Rails.logger.debug 'Creating featured base image...'
					start_time = Time.now
					Imogen::Iiif.convert(img, featured_base_cache_path, :png, {
						region: 'featured',
						size: 'full',
						rotation: generic_resource.required_rotation_for_upright_display.to_s
					})
					Rails.logger.debug 'Created featured base image in ' + (Time.now-start_time).to_s + ' seconds'
				end
			end
			
			# Kick off create and store jobs
			if DERIVATIVO[:queue_long_jobs]
				queue_create_and_store
			else
				create_and_store
			end
		ensure
			# Regardless of success or failure, derivative generation has ended,
			# so we will mark it as no longer in progress
			db_cache_record.update(derivative_generation_in_progress: false)
		end
  end
end