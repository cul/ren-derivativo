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
  
  
  namespace :queue do

    desc "Queue base derivatives for the given pids (base, featured base, iiif slices)"
    task :base_derivatives => :environment do
      start_time = Time.now
      
      if ENV['pids'].blank? && ENV['pidlist'].blank?
        puts 'Please specify one or more pids (e.g. pids=cul:123,cul:456 or pidlist=/path/to/list/file)'
        next
      end

      Derivativo::Pids.each(ENV['pids'], ENV['pidlist']) do |pid, counter, total|
        Resque.enqueue_to(Derivativo::Queue::LOW, CreateBaseDerivativesJob, id, Time.now.to_s)
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
  end
  
end
