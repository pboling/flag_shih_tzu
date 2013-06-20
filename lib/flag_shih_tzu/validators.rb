module ActiveModel
  module Validations

    class PresenceOfFlagsValidator < EachValidator
      def validate_each(record, attribute, value)
        value = record.send(:read_attribute_for_validation, attribute)
        check_flag(record, attribute)
        record.errors.add(attribute, :blank, options) if value.blank? or value == 0
      end

      private

      def check_flag(record, attribute)
        unless record.class.flag_columns.include? attribute.to_s
          raise ArgumentError.new("#{attribute} is not one of the flags columns (#{record.class.flag_columns.join(', ')})")
        end
      end
    end

    module HelperMethods
      # Validates that the specified attributes are flags and are not blank.
      # Happens by default on save. Example:
      #
      #  class Spaceship < ActiveRecord::Base
      #    include FlagShihTzu
      #
      #    has_flags({ 1 => :warpdrive, 2 => :hyperspace }, :column => 'engines')
      #    validates_presence_of_flags :engines
      #  end
      #
      # The engines attribute must be a flag in the object and it cannot be blank.
      #
      # Configuration options:
      # * <tt>:message</tt> - A custom error message (default is: "can't be blank").
      # * <tt>:on</tt> - Specifies when this validation is active. Runs in all
      #   validation contexts by default (+nil+), other options are <tt>:create</tt>
      #   and <tt>:update</tt>.
      # * <tt>:if</tt> - Specifies a method, proc or string to call to determine if
      #   the validation should occur (e.g. <tt>:if => :allow_validation</tt>, or
      #   <tt>:if => Proc.new { |user| user.signup_step > 2 }</tt>). The method, proc
      #   or string should return or evaluate to a true or false value.
      # * <tt>:unless</tt> - Specifies a method, proc or string to call to determine
      #   if the validation should not occur (e.g. <tt>:unless => :skip_validation</tt>,
      #   or <tt>:unless => Proc.new { |spaceship| spaceship.warp_step <= 2 }</tt>). The method,
      #   proc or string should return or evaluate to a true or false value.
      # * <tt>:strict</tt> - Specifies whether validation should be strict.
      #   See <tt>ActiveModel::Validation#validates!</tt> for more information.
      def validates_presence_of_flags(*attr_names)
        validates_with PresenceOfFlagsValidator, _merge_attributes(attr_names)
      end
    end

  end
end
