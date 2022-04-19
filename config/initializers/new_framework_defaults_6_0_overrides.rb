# In this file, we'll add any overrides for the new Rails 6 defaults.

# Because of a dependency on an old version of the cul_hydra gem, we can't use the newer
# zeitwerk autoloader -- otherwise we'll get an "uninitialized constant RDF::CUL" error.
# For now, we'll stick with the classic autoloader.
# This won't be a problem in the next version of Derivativo, which doesn't use the cul_hydra gem.
Rails.application.config.autoloader = :classic

# Disable cache versioning, which is a Rails 6 feature that's not compatible with the current
# version of our ActiveSupport::Cache::RedisStore cache (and we're not ready to update to a newer
# version of ActiveSupport::Cache::RedisStore yet).
Rails.application.config.active_record.cache_versioning = false
