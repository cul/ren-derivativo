# frozen_string_literal: true

module Derivativo::DeliveryAdapter
  def self.for(delivery_target_name)
    delivery_target_config = DERIVATIVO.dig(:delivery_targets, delivery_target_name.to_sym)
    raise "Could not find configuration for delivery target: #{delivery_target_name}" if delivery_target_config.nil?

    if delivery_target_config[:adapter] == 'hyacinth2'
      Derivativo::DeliveryAdapter::Hyacinth2.new(delivery_target_config)
    elsif delivery_target_config[:adapter] == 'hyacinth3'
      # Derivativo::DeliveryAdapter::Hyacinth3.new(delivery_target_config)
      raise 'The hyacinth3 delivery adapter is not yet available.'
    else
      # TODO: Add support for Hyacinth3
      raise "Unsupported delivery adapter for delivery target: #{delivery_target_name}"
    end
  end
end
