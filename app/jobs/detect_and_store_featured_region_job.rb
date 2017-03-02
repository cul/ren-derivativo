#require "open-uri"

class DetectAndStoreFeaturedRegionJob
  @queue = Derivativo::Queue::CREATE_AND_STORE # This is the default queue for this job

  def self.perform(id, queue_time_string=Time.now.to_s)
		Iiif.new({id: id}).get_cachable_property(Derivativo::Iiif::CacheKeys::FEATURED_REGION_KEY)
  end
end