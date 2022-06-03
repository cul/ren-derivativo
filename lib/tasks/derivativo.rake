module Derivativo
  module Pids
    def self.each(pids=nil,list=nil)
      pids = pids ? pids.split(',') : []
      total = pids.count
      open(list) {|b| total += b.count } if list
      counter = 0
      pids.each do |pid|
        counter += 1
        yield pid, counter, total
      end
      if list
        open(list) do |b|
          b.each do |pid|
            pid.strip!
            counter += 1
            yield pid, counter, total
          end
        end
      end
    end
  end
end

namespace :derivativo do
  namespace :path do
    task :for_pid => :environment do
      if ENV['pid'].blank?
        puts 'Please supply a pid (e.g. pid=abc:123)'
        next
      end

      pid = ENV['pid']
      puts "\nBase cache directory for #{pid}:\n" + Derivativo::CachePathBuilder.base_path_for_id(pid) + "\n"
      puts "\nIIIF directory for #{pid}:\n" + Derivativo::CachePathBuilder.iiif_path_for_id(pid) + "\n"
    end
  end

  desc "Generate cache for the given pids (via DerivativoResource#generate_cache)"
  task :generate_cache => :environment do
    start_time = Time.now
    queue_processing = (ENV['queue'].present? && ENV['queue'].downcase == 'true')

    if ENV['pids'].blank? && ENV['pidlist'].blank?
      puts 'Please specify one or more pids (e.g. pids=cul:123,cul:456 or pidlist=/path/to/list/file)'
      next
    end

    Derivativo::Pids.each(ENV['pids'], ENV['pidlist']) do |pid, counter, total|
      DerivativoResource.new(pid).generate_cache(queue_processing)
      puts "#{queue_processing ? 'Queued' : 'Processed'} #{counter} of #{total}: #{pid}"
    end

    puts "Done.  Took: #{(Time.now-start_time).to_s} seconds."
  end

  namespace :queue do

    desc "Queue base derivatives for the given pids"
    task :base_derivatives => :environment do
      start_time = Time.now

      if ENV['pids'].blank? && ENV['pidlist'].blank?
        puts 'Please specify one or more pids (e.g. pids=cul:123,cul:456 or pidlist=/path/to/list/file)'
        next
      end

      Derivativo::Pids.each(ENV['pids'], ENV['pidlist']) do |pid, counter, total|
        Resque.enqueue_to(Derivativo::Queue::LOW, CreateBaseDerivativesJob, pid, Time.now.to_s)
        puts "Queued #{counter} of #{total}: #{pid}"
      end

      puts "Done.  Took: #{(Time.now-start_time).to_s} seconds."
    end

    task :specific_raster => :environment do
      start_time = Time.now

      if ENV['pids'].blank? && ENV['pidlist'].blank?
        puts 'Please specify one or more pids (e.g. pids=cul:123,cul:456 or pidlist=/path/to/list/file)'
        next
      end

      validation_errors = false

      if ENV['region'].blank?
        puts 'Missing required arg: region'
        validation_errors = true
      end

      if ENV['size'].blank?
        puts 'Missing required arg: size'
        validation_errors = true
      end

      if ENV['rotation'].blank?
        puts 'Missing required arg: rotation'
        validation_errors = true
      end

      if ENV['format'].blank?
        puts 'Missing required arg: format (e.g. png, jpg)'
        validation_errors = true
      end

      unless ['png', 'jpg'].include?(ENV['format'])
        puts 'Format must be one of: png, jpg'
        validation_errors = true
      end

      next if validation_errors

      iiif_conditions = {}
      iiif_conditions['region'] = ENV['region'] # e.g. full
      iiif_conditions['size'] = ENV['size'] # e.g. full
      iiif_conditions['format'] = ENV['format'] # png, jpg
      iiif_conditions['rotation'] = ENV['rotation'] # e.g. 0

      Derivativo::Pids.each(ENV['pids'], ENV['pidlist']) do |pid, counter, total|
        Resque.enqueue_to(Derivativo::Queue::LOW, CreateRasterJob, iiif_conditions.merge({id: pid}), Time.now.to_s)
        puts "Queued #{counter} of #{total}: #{pid}"
      end

      puts "Done.  Took: #{(Time.now-start_time).to_s} seconds."
    end

    desc "Delete old audio/video access copies and regenerate new ones"
    task :regenerate_av_access_copies => :environment do
      start_time = Time.now

      if ENV['pids'].blank? && ENV['pidlist'].blank?
        puts 'Please specify one or more pids (e.g. pids=cul:123,cul:456 or pidlist=/path/to/list/file)'
        next
      end

      Derivativo::Pids.each(ENV['pids'], ENV['pidlist']) do |pid, counter, total|
        res = DerivativoResource.new(pid)
        fedora_obj = res.fedora_object

        if !Derivativo::FedoraObjectTypeCheck.is_generic_resource_audio_or_video?(fedora_obj)
          puts "Skipping #{pid} because it is not an audio or video file."
          next
        end

        access_ds_path = fedora_obj.datastreams['access']&.dsLocation&.gsub(/^file:/, '')
        File.delete(access_ds_path) if File.exist?(access_ds_path)
        res.generate_cache(true)

        puts "Queued #{counter} of #{total}: #{pid}"
      end

      puts "Done.  Took: #{(Time.now-start_time).to_s} seconds."
    end

  end

  namespace :clear do
    task :cache => :environment do
      if ENV['pids'].blank? && ENV['pidlist'].blank?
        puts 'Please specify one or more pids (e.g. pids=cul:123,cul:456 or pidlist=/path/to/list/file)'
        next
      end

      Derivativo::Pids.each(ENV['pids'], ENV['pidlist']) do |pid, counter, total|
        res = DerivativoResource.new(pid)
        res.clear_cache
        puts "Cleared #{counter} of #{total}: #{pid}"
      end
    end

    task :cachable_properties => :environment do
      if ENV['pids'].blank? && ENV['pidlist'].blank?
        puts 'Please specify one or more pids (e.g. pids=cul:123,cul:456 or pidlist=/path/to/list/file)'
        next
      end

      Derivativo::Pids.each(ENV['pids'], ENV['pidlist']) do |pid, counter, total|
        IiifResource.new(id: pid).clear_cachable_properties
        puts "Cleared #{counter} of #{total}: #{pid}"
      end
    end
  end

end
