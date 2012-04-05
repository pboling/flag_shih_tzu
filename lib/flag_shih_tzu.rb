require "rubygems"
require "active_record"
require "active_support/all"

module FlagShihTzu
  # taken from ActiveRecord::ConnectionAdapters::Column
  TRUE_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE']

  DEFAULT_COLUMN_NAME = 'flags'

  def self.included(base)
    base.extend(ClassMethods)
    base.class_attribute :flag_options unless defined?(base.flag_options)
    base.class_attribute :flag_mapping unless defined?(base.flag_mapping)
    base.class_attribute :flag_columns unless defined?(base.flag_columns)
  end

  class IncorrectFlagColumnException < Exception; end
  class NoSuchFlagQueryModeException < Exception; end
  class NoSuchFlagException < Exception; end
  class DuplicateFlagColumnException < Exception; end

  module ClassMethods
    def has_flags(*args)
      flag_hash, opts = parse_options(*args)
      opts = {
        :named_scopes => true,
        :column => DEFAULT_COLUMN_NAME,
        :flag_query_mode => :in_list,
        :strict => false
      }.update(opts)
      colmn = opts[:column].to_s

      return unless check_flag_column(colmn)

      # options are stored in a class level hash and apply per-column
      self.flag_options ||= {}
      self.flag_options[colmn] = opts

      # the mappings are stored in this class level hash and apply per-column
      self.flag_mapping ||= {}
      #If we already have an instance of the same column in the flag_mapping, then there is a double definition on a column
      raise DuplicateFlagColumnException if opts[:strict] && !self.flag_mapping[colmn].nil?
      self.flag_mapping[colmn] ||= {}

      # keep track of which flag columns are defined on this class
      self.flag_columns ||= []
      self.flag_columns << colmn

      flag_hash.each do |flag_key, flag_name|
        raise ArgumentError, "has_flags: flag keys should be positive integers, and #{flag_key} is not" unless is_valid_flag_key(flag_key)
        raise ArgumentError, "has_flags: flag names should be symbols, and #{flag_name} is not" unless is_valid_flag_name(flag_name)
        next if flag_mapping[colmn][flag_name] & (1 << (flag_key - 1)) # next if already methods defined by flagshitzu
        raise ArgumentError, "has_flags: flag name #{flag_name} already defined, please choose different name" if method_defined?(flag_name)

        flag_mapping[colmn][flag_name] = 1 << (flag_key - 1)

        class_eval <<-EVAL
          def #{flag_name}
            flag_enabled?(:#{flag_name}, '#{colmn}')
          end

          def #{flag_name}?
            flag_enabled?(:#{flag_name}, '#{colmn}')
          end

          def #{flag_name}=(value)
            FlagShihTzu::TRUE_VALUES.include?(value) ? enable_flag(:#{flag_name}, '#{colmn}') : disable_flag(:#{flag_name}, '#{colmn}')
          end

          def #{flag_name}_changed?
            if colmn_changes = changes['#{colmn}']
              flag_bit = self.class.flag_mapping['#{colmn}'][:#{flag_name}]
              (colmn_changes[0] & flag_bit) != (colmn_changes[1] & flag_bit)
            else
              false
            end
          end

          def self.#{flag_name}_condition(options = {})
            sql_condition_for_flag(:#{flag_name}, '#{colmn}', true, options[:table_alias] || self.table_name)
          end

          def self.not_#{flag_name}_condition
            sql_condition_for_flag(:#{flag_name}, '#{colmn}', false)
          end

          def self.set_#{flag_name}_sql
            sql_set_for_flag(:#{flag_name}, '#{colmn}', true)
          end

          def self.unset_#{flag_name}_sql
            sql_set_for_flag(:#{flag_name}, '#{colmn}', false)
          end
        EVAL

        # Define the named scopes if the user wants them and AR supports it
        if flag_options[colmn][:named_scopes] && respond_to?(named_scope_method)
          class_eval <<-EVAL
            #{named_scope_method} :#{flag_name}, lambda { { :conditions => #{flag_name}_condition } }
            #{named_scope_method} :not_#{flag_name}, lambda { { :conditions => not_#{flag_name}_condition } }
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
        has_ar = !!defined?(ActiveRecord) && self.respond_to?(:descends_from_active_record?)
        # Supposedly Rails 2.3 takes care of this, but this precaution is needed for backwards compatibility
        has_table = has_ar ? ActiveRecord::Base.connection.tables.include?(custom_table_name) : true

        if has_table
          found_column = columns.find {|column| column.name == colmn}
          #If you have not yet run the migration that adds the 'flags' column then we don't want to fail, because we need to be able to run the migration
          #If the column is there but is of the wrong type, then we must fail, because flag_shih_tzu will not work
          if found_column.nil?
            logger.warn("Error: Column '#{colmn}' doesn't exist on table '#{custom_table_name}'.  Did you forget to run migrations?") and return false
          elsif found_column.type != :integer
            raise IncorrectFlagColumnException.new("Table '#{custom_table_name}' must have an integer column named '#{colmn}' in order to use FlagShihTzu.") and return false
          end
        else
          # ActiveRecord gem probably hasn't loaded yet?
          logger.warn("FlagShihTzu#has_flags: Table '#{custom_table_name}' doesn't exist.  Have all migrations been run?") and return false
        end

        true
      end

      def sql_condition_for_flag(flag, colmn, enabled = true, custom_table_name = self.table_name)
        check_flag(flag, colmn)

        if flag_options[colmn][:flag_query_mode] == :bit_operator
          # use & bit operator directly in the SQL query.
          # This has the drawback of not using an index on the flags colum.
          "(#{custom_table_name}.#{colmn} & #{flag_mapping[colmn][flag]} = #{enabled ? flag_mapping[colmn][flag] : 0})"
        elsif flag_options[colmn][:flag_query_mode] == :in_list
          # use IN() operator in the SQL query.
          # This has the drawback of becoming a big query when you have lots of flags.
          neg = enabled ? "" : "not "
          "(#{custom_table_name}.#{colmn} #{neg}in (#{sql_in_for_flag(flag, colmn).join(',')}))"
        else
          raise NoSuchFlagQueryModeException
        end
      end

      # returns an array of integers suitable for a SQL IN statement.
      def sql_in_for_flag(flag, colmn)
        val = flag_mapping[colmn][flag]
        num = 2 ** flag_mapping[flag_options[colmn][:column]].length
        (1..num).select {|i| i & val == val}
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

      # Returns the correct method to create a named scope.
      # Use to prevent deprecation notices on Rails 3 when using +named_scope+ instead of +scope+.
      def named_scope_method
        # Can't use respond_to because both AR 2 and 3 respond to both +scope+ and +named_scope+.
        ActiveRecord::VERSION::MAJOR == 2 ? :named_scope : :scope
      end
  end

  # Performs the bitwise operation so the flag will return +true+.
  def enable_flag(flag, colmn = nil)
    colmn = determine_flag_colmn_for(flag) if colmn.nil?
    self.class.check_flag(flag, colmn)

    set_flags(self.flags(colmn) | self.class.flag_mapping[colmn][flag], colmn)
  end

  # Performs the bitwise operation so the flag will return +false+.
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

  def flags(colmn = DEFAULT_COLUMN_NAME)
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
      return DEFAULT_COLUMN_NAME if self.class.flag_mapping.nil?
      self.class.flag_mapping.each_pair do |colmn, mapping|
        return colmn if mapping.include?(flag)
      end
      raise NoSuchFlagException.new("determine_flag_colmn_for: Couldn't determine column for your flags!")
    end

end
