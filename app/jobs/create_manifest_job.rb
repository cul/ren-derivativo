require 'uri'

class CreateManifestJob
  @queue = Derivativo::Queue::HIGH # This is the default queue for this job

  def self.perform(id, host_url, queue_time_string=Time.now.to_s)
    Manifest.new(id, route_helper(host_url)).create_manifest_if_not_exist
  end
  def self.route_helper(host_url)
    uri = URI(host_url)
    opts = { host: uri.host, protocol: uri.scheme, port: uri.port }
    rhc = Class.new do
      include Rails.application.routes.url_helpers
      def self.default_url_options
        @opts
      end
    end
    rhc.instance_variable_set(:@opts, opts)
    rhc.new
  end
end