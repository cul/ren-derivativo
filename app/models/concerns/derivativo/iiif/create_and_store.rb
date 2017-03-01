module Derivativo::Iiif::CreateAndStore
  extend ActiveSupport::Concern
  
  JP2_DATASTREAM_NAME = 'zoom'
  THUMBNAIL_DATASTREAM_NAME = 'thumbnail'
  #CREATE_AND_STORE_TYPES = [JP2_DATASTREAM_NAME, THUMBNAIL_DATASTREAM_NAME] # Not storing JP2 images anymore
  CREATE_AND_STORE_TYPES = [THUMBNAIL_DATASTREAM_NAME]
  
  def queue_create_and_store
		Resque.enqueue_to(Derivativo::Queue::CREATE_AND_STORE, CreateAndStoreJob, id, Time.now.to_s)
	end
  
  def jp2_exists_in_fedora?
    obj = ActiveFedora::Base.find(self.id)
    obj.datastreams[JP2_DATASTREAM_NAME].present?
  end
  
  def thumbnail_exists_in_fedora?
    obj = ActiveFedora::Base.find(self.id)
    obj.datastreams[THUMBNAIL_DATASTREAM_NAME].present?
  end
  
  # Creates and stores all types that we want to create and store in Fedora (e.g. jp2 version, thumbnail, etc.)
  def create_and_store
    generic_resource = ActiveFedora::Base.find(id)
    
    # We only ever want to create base derivatives for GenericResources that are images (NOT PDFs)
    unless Derivativo::FedoraObjectTypeCheck.is_generic_resource_image?(generic_resource)
      if generic_resource.is_a?(GenericResource)
        Rails.logger.info "Skipped create and store images for GenericResource #{self.id} because it is not an image."
      else
        Rails.logger.info "Skipped create and store images for #{generic_resource.class.name} #{self.id} because it is not a GenericResource."
      end
      return
    end
    
		CREATE_AND_STORE_TYPES.each do |type|
			create_and_store_type(generic_resource, type)
		end
  end
  
  def create_and_store_type(generic_resource, type)
		# Do not create if type already exists
		return if generic_resource.datastreams[type].present?
		
		Rails.logger.debug "Creating and storing #{type} in Fedora..."
		start_time = Time.now
		
		file_extension = (type == JP2_DATASTREAM_NAME ? 'jp2' : 'jpg')
		img_tempfile = Tempfile.new(['img', '.' + file_extension])
		
		begin
			img_tempfile_path = img_tempfile.path
			# In addition to being user-readable by default,
			# make sure that tempfile is group-readable so
			# that Fedora (which runs as a different user than
			# this web app) can read it
			File.chmod(0640, img_tempfile_path)
								 
			image_props = (type == JP2_DATASTREAM_NAME ? {:format => 'jp2'} : {:format => 'jpg'})
			
			generic_resource.with_ds_resource('content', (! DERIVATIVO['no_mount']) ) do |image_path|	
				Imogen.with_image(image_path) do |img|
					image_props[:image_width] = img.width.to_s
					image_props[:image_length] = img.height.to_s
					#long = (img.width > img.height) ? img.width : img.height
					Imogen::Iiif.convert(img, img_tempfile_path, (type == JP2_DATASTREAM_NAME ? :jp2 : :jpeg), {
						region: 'full',
						size: (type == JP2_DATASTREAM_NAME ? 'full' : "!#{DERIVATIVO['thumbnail_size']},#{DERIVATIVO['thumbnail_size']}")
					})
				end
			end
				
			# Write img_tempfile content to fedora managed datastream
			generic_resource.datastreams[type]
			content_ds = generic_resource.datastreams['content']
			deriv_ds = generic_resource.create_datastream(
				ActiveFedora::Datastream, type,
				:controlGroup => 'M',
				:mimeType => type == JP2_DATASTREAM_NAME ? 'image/jp2' : 'image/jpeg',
				:dsLabel => "#{type}.#{file_extension}",
				:versionable => false
			)
			generic_resource.add_datastream(deriv_ds)
			
			local_upload_file_path = nil
			begin
				if DERIVATIVO['no_mount'] # running locally, need to upload content over http[s]
					open(img_tempfile_path,:encoding=>"BINARY") do |blob|
						image_props[:extent] = blob.size.to_s
						deriv_ds.content = blob.read
					end
				else
					# We've got Fedora mounted locally.  Copy new file there for upload so that we don't have to send it via http.
					local_upload_file_path = File.join(ActiveFedora.config.credentials[:upload_dir], Digest::SHA256.hexdigest(img_tempfile_path))
					FileUtils.copy(img_tempfile_path, local_upload_file_path)
					image_props[:extent] = File.size(local_upload_file_path).to_s
					deriv_ds.dsLocation = 'file://' + local_upload_file_path
				end
				
				rels_int = generic_resource.rels_int
				rels_int.relationships.each do |rel|
					if rel.predicate.to_s == "http://www.w3.org/2003/12/exif/ns#xResolution" or rel.predicate.to_s == "http://www.w3.org/2003/12/exif/ns#yResolution"
						rels_int.graph.delete(rel)
						rels_int.relationships_will_change!
					end
				end
				image_props.each do |k,v|
					rels_int.clear_relationship(deriv_ds, k)
					rels_int.add_relationship(deriv_ds, k, v, k != :format_of)
				end
				
				if type == JP2_DATASTREAM_NAME
					rels_int.clear_relationship(content_ds, :foaf_thumbnail)
					rels_int.add_relationship(content_ds, :foaf_thumbnail, "#{generic_resource.internal_uri}/#{deriv_ds.dsid}")
				elsif type == THUMBNAIL_DATASTREAM_NAME
					rels_int.clear_relationship(content_ds, :foaf_zooming)
					rels_int.add_relationship(content_ds, :foaf_zooming, "#{generic_resource.internal_uri}/#{deriv_ds.dsid}")
				end
				
				Retriable.retriable on: [RestClient::RequestTimeout], tries: 3, base_interval: 5 do
					deriv_ds.save
					rels_int.content = rels_int.to_rels_int # We're doing this because there's some weird bug in the rels_int gem (ds doesn't know it was updated)
					rels_int.save if rels_int.changed?
				end
				
			ensure
				File.unlink(local_upload_file_path) unless local_upload_file_path.nil? # Only runs if we did a local file upload
			end
			
			Rails.logger.debug "Finished storing #{type} in Fedora.  Took #{(Time.now-start_time).to_s} seconds"
		ensure
			# We're done with the img tempfile
			img_tempfile.unlink
		end
	end
  
end