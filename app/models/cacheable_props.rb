class CacheableProps
  attr_reader :identifier

  def initialize(resource_identifier)
    @identifier = resource_identifier
  end

  def db_cache_record
    return @db_cache_record if @db_cache_record
    @db_cache_record = DbCacheRecord.find_by(identifier: self.identifier) || DbCacheRecord.create!(identifier: identifier)
  end

  def processing
    # TODO: Add redis layer
    db_cache_record.processing
  end

  def processing=(val)
    # TODO: Add redis layer
    db_cache_record.update!(processing: val)
  end

  def use_placeholder_image
    # TODO: Add redis layer
    db_cache_record.use_placeholder_image
  end

  def use_placeholder_image=(val)
    # TODO: Add redis layer
    db_cache_record.update!(use_placeholder_image: val)
  end

  def base_width
    # TODO: Add redis layer
    db_cache_record.base_width
  end

  def base_width=(val)
    # TODO: Add redis layer
    db_cache_record.update!(base_width: val)
  end

  def base_height
    # TODO: Add redis layer
    db_cache_record.base_height
  end

  def base_height=(val)
    db_cache_record.update!(base_height: val)
  end
end
