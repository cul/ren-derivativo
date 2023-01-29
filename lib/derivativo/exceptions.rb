# frozen_string_literal: true

module Derivativo
  module Exceptions
    class DerivativoError < StandardError; end

    class MultiplePidsFoundForIdentifier < DerivativoError; end
    class UnsupportedRegionError < DerivativoError; end
  end
end
