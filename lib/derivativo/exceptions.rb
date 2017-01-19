module Derivativo::Exceptions
  class DerivativoError < StandardError; end

  class UnsupportedRegionError < DerivativoError; end
end
