module ActiveAttr
  module Matchers
    # Specify that a model should have an attribute matching the criteria. See
    # {HaveAttributeMatcher}
    #
    # @example Person should have a name attribute
    #   describe Person do
    #     it { should have_attribute(:first_name) }
    #   end
    #
    # @param [Symbol, String, #to_sym] attribute_name
    #
    # @return [ActiveAttr::HaveAttributeMatcher]
    #
    # @since 0.2.0
    def have_attribute(attribute_name)
      HaveAttributeMatcher.new(attribute_name)
    end

    # Verifies that an ActiveAttr-based model has an attribute matching the
    # given criteria. See {Matchers#have_attribute}
    #
    # @since 0.2.0
    class HaveAttributeMatcher
      attr_reader :attribute_name
      private :attribute_name

      # @return [String] Description
      # @private
      def description
        "has #{@description}"
      end

      # @return [String] Failure message
      # @private
      def failure_message
        if missing_ancestors.any?
          missing_ancestor = missing_ancestors.first
          "expected #{@model_class.name} to include #{missing_ancestor}"
        else
          "expected #{@model_class.name} to have #{@description}"
        end
      end

      # @param [Symbol, String, #to_sym] attribute_name
      # @private
      def initialize(attribute_name)
        raise TypeError, "can't convert #{attribute_name.class} into Symbol" unless attribute_name.respond_to? :to_sym
        @description = "attribute named #{attribute_name}"
        @expected_ancestors = ["ActiveAttr::Attributes"]
        @attribute_name = attribute_name.to_sym
        @type = nil
        @default_value_set = false
      end

      # Specify that the attribute should have the given type
      #
      # @example Person's first name should be a String
      #   describe Person do
      #     it { should have_attribute(:first_name).of_type(String) }
      #   end
      #
      # @param [Class] type The expected type
      #
      # @return [HaveAttributeMatcher] The matcher
      #
      # @since 0.5.0
      def of_type(type)
        @description << " of type #{type}"
        @expected_ancestors << "ActiveAttr::TypecastedAttributes"
        @type = type
        self
      end

      # @private
      def matches?(model_or_model_class)
        @model_class = Class === model_or_model_class ? model_or_model_class : model_or_model_class.class
        missing_ancestors.none? && attribute_definition && type_matches? && default_matches?
      end

      # @return [String] Negative failure message
      # @private
      def negative_failure_message
        "expected #{@model_class.name} to not have #{@description}"
      end

      # Specify that the attribute should have the given default value
      #
      # @example Person's first name should default to John
      #   describe Person do
      #     it do
      #       should have_attribute(:first_name).with_default_value_of("John")
      #     end
      #   end
      #
      # @param [Object] default_value The expected default value
      #
      # @return [HaveAttributeMatcher] The matcher
      #
      # @since 0.5.0
      def with_default_value_of(default_value)
        @description << " with a default value of #{default_value.inspect}"
        @expected_ancestors << "ActiveAttr::AttributeDefaults"
        @default_value = default_value
        @default_value_set = true
        self
      end

      private

      def attribute_definition
        @model_class.attributes[attribute_name]
      end

      def missing_ancestors
        model_ancestor_names = @model_class.ancestors.map(&:name)

        @expected_ancestors.reject do |ancestor_name|
          model_ancestor_names.include? ancestor_name
        end
      end

      def default_matches?
        !@default_value_set || attribute_definition[:default] == @default_value
      end

      def type_matches?
        !@type || @model_class._attribute_type(attribute_name) == @type
      end
    end
  end
end
