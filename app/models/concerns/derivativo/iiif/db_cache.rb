module Derivativo::Iiif::DbCache
  extend ActiveSupport::Concern
  
  def db_cache_record
    @db_cache_recod ||= begin
      DbCacheRecord.find_by(pid: @id) || DbCacheRecord.create(pid: @id, data: {})
    end
  end
  
  def db_cache_clear
    db_cache_record.destroy
    @db_cache_record = nil
  end
  
  def db_cache_set(key, value)
    raise_error_if_invalid_cache_key(key)
    db_cache_record.data[key] = value
    db_cache_record.save
  end
  
  def db_cache_get(key)
    raise_error_if_invalid_cache_key(key)
    db_cache_record.data[key]
  end
  
  def db_cache_has?(key)
    raise_error_if_invalid_cache_key(key)
    db_cache_record.data.key?(key)
  end
  
  def raise_error_if_invalid_cache_key(key)
    raise Derivativo::Exceptions::InvalidCacheKey, "Invalid key: #{key}" unless Derivativo::Iiif::CacheKeys::PROPERTY_CACHE_KEYS.include?(key)
  end
  
end