module Derivativo::Iiif::DbCache
  extend ActiveSupport::Concern
  
  def db_cache_record
    @db_cache_recod ||= begin
      DbCacheRecord.find_by(pid: self.id) || DbCacheRecord.create(pid: self.id, data: {})
    end
  end
  
  def db_cache_clear
    db_cache_record.data = {}
    db_cache_record.save
  end
  
  def db_cache_set(key, value, save_db_cache_record_after_set = true)
    raise_error_if_invalid_cache_key(key)
    db_cache_record.data['key'] = value
    db_cache_record.save if save_db_cache_record_after_set
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
    raise "Invalid key: #{key}" unless Derivativo::Iiif::CacheKeys::PROPERTY_CACHE_KEYS.include?(key)
  end
  
end