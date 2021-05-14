# frozen_string_literal: true

module DefaultValues
  # rubocop:disable Naming/AccessorMethodName
  def set_default_values_if_present(options = {})
    options.each do |attribute, value|
      send(:"#{attribute}=", send(:"#{attribute}") || value) if has_attribute?(attribute)
    end
  end
  private :set_default_values_if_present
  # rubocop:enable Naming/AccessorMethodName
end
