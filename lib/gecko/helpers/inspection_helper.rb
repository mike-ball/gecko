module Gecko
  module Helpers
    module InspectionHelper
      # Overrides the default inspect to just return the defined attributes
      #
      # @example
      #   company.inspect #=> <Gecko::Record::Company id=123 name="Gecko Inc">
      #
      # @return [String]
      #
      # @api public
      def inspect
        inspection = self.class.attribute_set.collect do |attribute|
          name = attribute.name
          "#{name}: #{attribute_for_inspect(name)}"
        end.join(", ")
        "#<#{self.class} #{inspection}>"
      end

    private
      # Returns an #inspect-like string for the value of the attribute attr_name.
      # String attributes are truncated up to 50 characters,
      # and Date and Time attributes are returned in the :db format.
      # Other attributes return the value of #inspect without modification.
      # Duplicated from Rails implementation
      #
      # @example
      #   company.inspect #=> <Gecko::Record::Company id=123 name="Gecko Inc">
      #
      # @return [String]
      #
      # @api private
      def attribute_for_inspect(attr_name)
        value = attributes[attr_name]

        if value.is_a?(String) && value.length > 50
          "#{value[0..50]}...".inspect
        elsif value.is_a?(Date) || value.is_a?(Time)
          %("#{value.to_s(:db)}")
        else
          value.inspect
        end
      end
    end
  end
end
