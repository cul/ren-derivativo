namespace :featured_region do
	task reassign: :environment do
		pid = ENV['pid']
		unless pid && pid =~ /[a-z]+:[A-Za-z0-9\-]+/
			puts "pid is a required parameter"
			next
		end
		featured_region = ENV['region']
		top, left, width, height = featured_region.to_s.split(',').map(&:to_i)
		unless (top >= 0) &&(left >= 0) && (width >= 768) && (width == height)
			puts "region must describe a square within image of at least 768px side (given region '#{featured_region}')"
			next
		end
		iiif_resource = IiifResource.new(id: pid)
		representative_generic_resource = iiif_resource.fedora_get_representative_generic_resource
		unless pid == representative_generic_resource.pid
			puts "pid must identify a GenericResource/Asset: #{pid} is a #{iiif_resource.fedora_object.class.name}"
			next
		end
		# Get image dimensions from Fedora object, or get dimensions from original content if unavailable (and save those dimensions in Fedora for future retrieval)
		original_image_width, original_image_height = iiif_resource.send :original_image_dimensions

		unless original_image_width && original_image_height
			puts "Original asset has not yet been analyzed; cannot reassign featured region"
			next
		end
		unless (original_image_width >= left + width) && (original_image_height >= top + height)
			puts "region #{featured_region} is not within original image dimensions #{original_image_width}x#{original_image_height}"
			next
		end
		representative_generic_resource.clear_relationship(:region_featured)
		representative_generic_resource.add_relationship(:region_featured, featured_region, true)
		Retriable.retriable on: [RestClient::RequestTimeout], tries: 3, base_interval: 5 do
			representative_generic_resource.save(update_index: false)
		end
		# clear the cache and the cacheable properties
		# this will unfortunately look the Fedora object up again, because it initializes an IiifResource
		#  which only takes string ID params
		DerivativoResource.new(representative_generic_resource).clear_cache
		puts "region param: #{ featured_region } assigned region: #{IiifResource.new(id: pid).fedora_get_featured_region}"
	end
end
