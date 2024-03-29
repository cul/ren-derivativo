# frozen_string_literal: true

module Derivativo
  module Exceptions
    class DerivativoError < StandardError; end

    class UnhandledFileType < DerivativoError; end
    class UnhandledLocationFormat < DerivativoError; end
    class UnreadableFilePath < DerivativoError; end

    class InvalidJobType < DerivativoError; end
    class OptionError < DerivativoError; end

    class ConversionError < DerivativoError; end
    class TimeoutException < DerivativoError; end
  end
end
