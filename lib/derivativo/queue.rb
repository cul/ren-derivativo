module Derivativo::Queue

  HIGH = 'high'
  LOW = 'low'
  CREATE_AND_STORE = 'create_and_store'
  MEDIA_CONVERSION_LOW = 'media_conversion_low'
  TEXT_EXTRACTION_LOW = 'text_extraction_low'
  MEDIA_CONVERSION_HIGH = 'media_conversion_high'

  QUEUES_IN_DESCENDING_PRIORITY_ORDER = [HIGH, LOW, CREATE_AND_STORE, MEDIA_CONVERSION_HIGH, TEXT_EXTRACTION_LOW, MEDIA_CONVERSION_LOW]

end
