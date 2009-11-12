module FlagShihTzu
  TRUE_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE'] # taken from ActiveRecord::ConnectionAdapters::Column

  def self.included(base)
    base.extend(ClassMethods)
  end
  
  class IncorrectFlagColumnException < Exception; end
  class NoSuchFlagException < Exception; end

  module ClassMethods
    def has_flags(*args)
      flag_hash, options = parse_options(*args)
      options = {:named_scopes => true, :column => 'flags', :verbose => false}.update(options)

      class_inheritable_reader :flag_column
      write_inheritable_attribute(:flag_column, options[:column])

      flag_column = options[:column]
      check_flag_column(flag_column)

      class_inheritable_hash :flag_mapping
      # if has_flags is used more than once in a single class, then flag_mapping will already have data in it in successive declarations
      write_inheritable_attribute(:flag_mapping, {}) if flag_mapping.nil?

      # initialize flag_mapping for this column
      flag_mapping[flag_column] ||= {}

      flag_hash.each do |flag_key, flag_name|
        raise ArgumentError, "has_flags: flag keys should be positive integers, and #{flag_key} is not" unless is_valid_flag_key(flag_key)
        raise ArgumentError, "has_flags: flag names should be symbols, and #{flag_name} is not" unless is_valid_flag_name(flag_name)
        raise ArgumentError, "has_flags: flag name #{flag_name} already defined, please choose different name" if method_defined?(flag_name)

        flag_mapping[flag_column][flag_name] = 1 << (flag_key - 1)

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

        if respond_to?(:named_scope) && options[:named_scopes]
          class_eval <<-EVAL
            named_scope :#{flag_name}, lambda { { :conditions => #{flag_name}_condition } }
            named_scope :not_#{flag_name}, lambda { { :conditions => not_#{flag_name}_condition } }
          EVAL
        end
      end
      
    end

    def check_flag(flag, colmn)
      raise ArgumentError, "Column name '#{colmn}' for flag '#{flag}' is not a string" unless colmn.is_a?(String)
      raise ArgumentError, "Invalid flag '#{flag}'" if flag_mapping[colmn].nil? || !flag_mapping[colmn].include?(flag)
    end

    
    private
    
      def parse_options(*args)
        options = args.shift
        if args.size >= 1
          add_options = args.shift
        else
          add_options = options.keys.select {|key| !key.is_a?(Fixnum)}.inject({}) do |hash, key|
            hash[key] = options.delete(key)
            hash
          end
        end
        return options, add_options
      end

      def check_flag_column(colmn, custom_table_name = self.table_name)
        # If you aren't using ActiveRecord (eg. you are outside rails) then do not fail here
        # If you are using ActiveRecord then you only want to check for the table if the table exists so it won't fail pre-migration
        has_ar = defined?(ActiveRecord) && self.is_a?(ActiveRecord::Base)
        # Supposedly Rails 2.3 takes care of this, but this precaution is needed for backwards compatibility
        has_table = has_ar ? ActiveRecord::Base.connection.tables.include?(custom_table_name) : true

        puts "Error: Table '#{custom_table_name}' doesn't exist" and return false unless has_table
        if !has_ar || (has_ar && has_table)
          unless columns.any? { |column| column.name == colmn && column.type == :integer }
            logger.warn("Warning: Table '#{custom_table_name}' must have an integer column named '#{colmn}' in order to use FlagShihTzu")
          end
        end
      end

      def sql_condition_for_flag(flag, colmn, enabled = true, custom_table_name = self.table_name)
        check_flag(flag, colmn)

        "(#{custom_table_name}.#{colmn} & #{flag_mapping[colmn][flag]} = #{enabled ? flag_mapping[colmn][flag] : 0})"
      end

      def sql_set_for_flag(flag, colmn, enabled = true, custom_table_name = self.table_name)
        check_flag(flag, colmn)

        "#{custom_table_name}.#{colmn} = #{custom_table_name}.#{colmn} #{enabled ? "| " : "& ~" }#{flag_mapping[colmn][flag]}"
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
