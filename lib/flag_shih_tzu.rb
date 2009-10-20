module FlagShihTzu
  TRUE_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE'] # taken from ActiveRecord::ConnectionAdapters::Column

  def self.included(base)
    base.extend(ClassMethods)
  end
  
  class IncorrectFlagColumnException < Exception; end
  class NoSuchFlagException < Exception; end

  module ClassMethods
    def has_flags(flag_hash, options = {})
      options = {:named_scopes => true, :column => 'flags'}.update(options)

      flag_column = options[:column]
      check_flag_column(flag_column)

      @flag_mapping ||= {}

      flag_hash.each do |flag_key, flag_name|
        raise ArgumentError, "has_flags: flag keys should be positive integers, and #{flag_key} is not" unless is_valid_flag_key(flag_key)
        raise ArgumentError, "has_flags: flag names should be symbols, and #{flag_name} is not" unless is_valid_flag_name(flag_name)

        @flag_mapping[flag_column] ||= {}
        @flag_mapping[flag_column][flag_name] = 1 << (flag_key - 1)

        if method_defined?(flag_name)
          raise ArgumentError, "has_flags: flag name #{flag_name} already defined, please choose different name"
        end

        class_eval <<-EVAL
          def #{flag_name}
            flag_enabled?(:#{flag_name}, '#{flag_column}')
          end

          def #{flag_name}?
            flag_enabled?(:#{flag_name}, '#{flag_column}')
          end

          def #{flag_name}=(value)
            FlagShihTzu::TRUE_VALUES.include?(value) ? enable_flag(:#{flag_name}, '#{flag_column}') : disable_flag(:#{flag_name}, '#{flag_column}')
          end

          def self.#{flag_name}_condition
            sql_condition_for_flag(:#{flag_name}, '#{flag_column}', true)
          end

          def self.not_#{flag_name}_condition
            sql_condition_for_flag(:#{flag_name}, '#{flag_column}', false)
          end
        EVAL

        if options[:named_scopes]
          class_eval <<-EVAL
            named_scope :#{flag_name}, lambda { { :conditions => #{flag_name}_condition } }
            named_scope :not_#{flag_name}, lambda { { :conditions => not_#{flag_name}_condition } }
          EVAL
        end
      end
    end

    def flag_mapping
      @flag_mapping
    end

    def check_flag(flag, colmn)
      raise ArgumentError, "Invalid flag '#{flag}'" unless flag_mapping[colmn].include?(flag)
    end

    private

      def check_flag_column(colmn)
        unless columns.any? { |column| column.name == colmn && column.type == :integer }
          raise IncorrectFlagColumnException.new("Table '#{table_name}' must have an integer column named '#{colmn}' in order to use FlagShihTzu")
        end
      end

      def sql_condition_for_flag(flag, colmn, enabled = true)
        check_flag(flag, colmn)

<<<<<<< HEAD:lib/flag_shih_tzu.rb
        "(#{table_name}.#{flag_column} & #{flag_mapping[flag]} = #{enabled ? flag_mapping[flag] : 0})"
=======
        "(#{table_name}.#{colmn.to_s} & #{flag_mapping[colmn][flag]} = #{enabled ? flag_mapping[colmn][flag] : 0})"
>>>>>>> ppeszko/master:lib/flag_shih_tzu.rb
      end

      def is_valid_flag_key(flag_key)
        flag_key > 0 && flag_key == flag_key.to_i
      end

      def is_valid_flag_name(flag_name)
        flag_name.is_a?(Symbol)
      end
  end

  def enable_flag(flag, colmn = nil)
    colmn = determine_flag_colmn_for(flag) if colmn.nil?
    self.class.check_flag(flag, colmn)

    set_flags(self.flags(colmn) | self.class.flag_mapping[colmn][flag], colmn)
  end

  def disable_flag(flag, colmn = nil)
    colmn = determine_flag_colmn_for(flag) if colmn.nil?
    self.class.check_flag(flag, colmn)

    set_flags(self.flags(colmn) & ~self.class.flag_mapping[colmn][flag], colmn)
  end

  def flag_enabled?(flag, colmn = nil)
    colmn = determine_flag_colmn_for(flag) if colmn.nil?
    self.class.check_flag(flag, colmn)

    get_bit_for(flag, colmn) == 0 ? false : true
  end

  def flag_disabled?(flag, colmn = nil)
    colmn = determine_flag_colmn_for(flag) if colmn.nil?
    self.class.check_flag(flag, colmn)

    !flag_enabled?(flag, colmn)
  end

  def flags(colmn = 'flags')
    self[colmn] || 0
  end

  def set_flags(value, colmn)
    self[colmn] = value
  end

  private

    def get_bit_for(flag, colmn)
      self.flags(colmn) & self.class.flag_mapping[colmn][flag]
    end

    def determine_flag_colmn_for(flag)
      return 'flags' if self.class.flag_mapping.nil?
      self.class.flag_mapping.each_pair do |colmn, mapping|
        return colmn if mapping.include?(flag)
      end
      raise NoSuchFlagException.new("determine_flag_colmn_for: Couldn't determine column for your flags!")
    end

end
