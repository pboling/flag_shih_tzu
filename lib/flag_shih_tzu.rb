module FlagShihTzu
  TRUE_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE'] # taken from ActiveRecord::ConnectionAdapters::Column

  def self.included(base)
    base.extend(ClassMethods)
  end
  
  class IncorrectFlagColumnException < Exception; end
  class NoSuchFlagException < Exception; end

  module ClassMethods
    def has_flags(flag_hash, options = {})
      options = {:named_scopes => true, :column => 'flags', :verbose => false}.update(options)

      class_inheritable_reader :flag_column
      write_inheritable_attribute(:flag_column, options[:column])

      flag_column = options[:column]
      # If the flag column is not in the table, then we cannot declare the rest of this code (it would fail).
      # This should allow the has_flags to be in the model in development even before the migration runs,
      #   and crucially, *when* the migration is running.
      if check_flag_column(flag_column)

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
      
    end

    def check_flag(flag, colmn)
      raise ArgumentError, "Column name '#{colmn}' for flag '#{flag}' is not a string" unless colmn.is_a?(String)
      raise ArgumentError, "Invalid flag '#{flag}'" if flag_mapping[colmn].nil? || !flag_mapping[colmn].include?(flag)
    end

    
    private
    
    def check_flag_column(colmn, custom_table_name = self.table_name)
      # If you aren't using ActiveRecord (eg. you are outside rails) then do not fail here
      # If you are using ActiveRecord then you only want to check for the table if the table exists so it won't fail pre-migration
      has_ar = (defined?(ActiveRecord) && ActiveRecord::Base.connection.respond_to?(:tables))
      puts "ActiveRecord, or database connection not found. FlagShihTzu may not work without Active Record." and return true unless has_ar
      # Supposedly Rails 2.3 takes care of this, but this precaution is needed for backwards compatibility
      if ActiveRecord::Base.connection.tables.include?(custom_table_name)
        col = columns.select {|column| column.name == colmn }.first
        #If you have not yet run the migration that adds the 'flags' column then we don't want to fail, because we need to be able to run the migration
        #If the column is there but is of the wrong type, then we must fail, because flag_shih_tzu will not work
        case col
          when nil then puts "Error: Column '#{colmn}' doesn't exist on table '#{custom_table_name}'.  Did you forget to run migrations?" and return false
          else raise IncorrectFlagColumnException.new("Table '#{custom_table_name}' must have an integer column named '#{colmn}' in order to use FlagShihTzu") and return false unless col.type == :integer
        end
      else
        puts "Error: Table '#{custom_table_name}' doesn't exist" and return false
      end
      return true
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
