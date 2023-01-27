# frozen_string_literal: true

module Derivativo
  module Exceptions
    class DerivativoError < StandardError; end

    class UnsupportedRegionError < DerivativoError; end
  end
end
