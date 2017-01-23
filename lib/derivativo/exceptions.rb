module Derivativo::Exceptions
  class DerivativoError < StandardError; end

  class UnsupportedRegionError < DerivativoError; end
  class ResourceNotFound < DerivativoError; end
  
end
