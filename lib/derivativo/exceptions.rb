# frozen_string_literal: true

module Derivativo::Exceptions
  class DerivativoError < StandardError; end

  class MultiplePidsFoundForIdentifier < DerivativoError; end
  class BaseNotFoundError < DerivativoError; end
  class PlaceholderBaseNotFoundError < DerivativoError; end
  class AccessCopyNotFoundError < DerivativoError; end
  class UnsupportedRegionError < DerivativoError; end
end
