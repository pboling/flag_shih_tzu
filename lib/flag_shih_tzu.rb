# Would like to support other database adapters so no more hard dependency on Active Record.
require "flag_shih_tzu/validators"

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
      flag_hash, opts = parse_flag_options(*args)
      opts = {
        :named_scopes => true,
        :column => DEFAULT_COLUMN_NAME,
        :flag_query_mode => :in_list, # or :bit_operator
        :strict => false,
        :check_for_column => true
      }.update(opts)
      colmn = opts[:column].to_s
      if !is_valid_flag_column_name(opts[:column])
        warn "FlagShihTzu says: Please use a String to designate column names! I see you here: #{caller.first}"
        opts[:column] = opts[:column].to_s
      end
      colmn = opts[:column]
      if opts[:check_for_column] && !check_flag_column(colmn)
        warn "FlagShihTzu says: Flag column #{colmn} appears to be missing!\nTo turn off this warning set check_for_column: false in has_flags definition here: #{caller.first}"
        return
      end

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
        #puts "Defined: #{flag_key} as #{flag_mapping[colmn][flag_name]}"

        class_eval <<-EVAL, __FILE__, __LINE__ + 1
          def #{flag_name}
            flag_enabled?(:#{flag_name}, '#{colmn}')
          end
          alias :#{flag_name}? :#{flag_name}

          def #{flag_name}=(value)
            FlagShihTzu::TRUE_VALUES.include?(value) ? enable_flag(:#{flag_name}, '#{colmn}') : disable_flag(:#{flag_name}, '#{colmn}')
          end

          def not_#{flag_name}
            !#{flag_name}
          end
          alias :not_#{flag_name}? :not_#{flag_name}

          def not_#{flag_name}=(value)
            FlagShihTzu::TRUE_VALUES.include?(value) ? disable_flag(:#{flag_name}, '#{colmn}') : enable_flag(:#{flag_name}, '#{colmn}')
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

          def self.#{colmn.singularize}_values_for(*flag_names)
            values = []
            flag_names.each do |flag_name|
              if respond_to?(flag_name)
                values_for_flag = send(:sql_in_for_flag, flag_name, '#{colmn}')
                values = if values.present?
                  values & values_for_flag
                else
                  values_for_flag
                end
              end
            end

            values.sort
          end
        EVAL

        if colmn != DEFAULT_COLUMN_NAME
          class_eval <<-EVAL, __FILE__, __LINE__ + 1

            def all_#{colmn}
              all_flags('#{colmn}')
            end

            def selected_#{colmn}
              selected_flags('#{colmn}')
            end

            def select_all_#{colmn}
              select_all_flags('#{colmn}')
            end

            def unselect_all_#{colmn}
              unselect_all_flags('#{colmn}')
            end

            # useful for a form builder
            def selected_#{colmn}=(selected_flags)
              unselect_all_flags('#{colmn}')
              selected_flags.each do |selected_flag|
                enable_flag(selected_flag.to_sym, '#{colmn}') if selected_flag.present?
              end
            end

            def has_#{colmn.singularize}?
              not selected_#{colmn}.empty?
            end

          EVAL
        end

        # Define bang methods when requested
        if flag_options[colmn][:bang_methods]
          class_eval <<-EVAL, __FILE__, __LINE__ + 1
            def #{flag_name}!
              enable_flag(:#{flag_name}, '#{colmn}')
            end

            def not_#{flag_name}!
              disable_flag(:#{flag_name}, '#{colmn}')
            end
          EVAL
        end

        # Define the named scopes if the user wants them and AR supports it
        if flag_options[colmn][:named_scopes]
          if ActiveRecord::VERSION::MAJOR == 2 && respond_to?(:named_scope)
            # Prevent deprecation notices on Rails 3 when using +named_scope+ instead of +scope+.
            class_eval <<-EVAL, __FILE__, __LINE__ + 1
              named_scope :#{flag_name}, lambda { { :conditions => #{flag_name}_condition } }
              named_scope :not_#{flag_name}, lambda { { :conditions => not_#{flag_name}_condition } }
            EVAL
          elsif respond_to?(:scope)
            # Prevent deprecation notices on Rails 4 when using +conditions+ instead of +where+.
            class_eval <<-EVAL, __FILE__, __LINE__ + 1
              scope :#{flag_name}, lambda { where(#{flag_name}_condition) }
              scope :not_#{flag_name}, lambda { where(not_#{flag_name}_condition) }
            EVAL
          end
        end
      end

    end

    def check_flag(flag, colmn)
      raise ArgumentError, "Column name '#{colmn}' for flag '#{flag}' is not a string" unless colmn.is_a?(String)
      raise ArgumentError, "Invalid flag '#{flag}'" if flag_mapping[colmn].nil? || !flag_mapping[colmn].include?(flag)
    end

    # Returns SQL statement to enable/disable flag.
    # Automatically determines the correct column.
    def set_flag_sql(flag, value, colmn = nil, custom_table_name = self.table_name)
      colmn = determine_flag_colmn_for(flag) if colmn.nil?
      sql_set_for_flag(flag, colmn, value, custom_table_name)
    end

    def determine_flag_colmn_for(flag)
      return DEFAULT_COLUMN_NAME if self.flag_mapping.nil?
      self.flag_mapping.each_pair do |colmn, mapping|
        return colmn if mapping.include?(flag)
      end
      raise NoSuchFlagException.new("determine_flag_colmn_for: Couldn't determine column for your flags!")
    end

    def chained_flags_with(*args)
      if (ActiveRecord::VERSION::MAJOR >= 3)
        where(chained_flags_condition(*args))
      else
        all(:conditions => chained_flags_condition(*args))
      end
    end

    def chained_flags_condition(colmn, *args)
      "(#{self.table_name}.#{colmn} in (#{chained_flags_values(colmn, *args).join(',')}))"
    end

    def flag_keys(colmn = DEFAULT_COLUMN_NAME)
      flag_mapping[colmn].keys
    end

    private

      def flag_value_range_for_column(colmn)
        max = flag_mapping[colmn].values.max
        Range.new(0, (2 * max) - 1)
      end

      def chained_flags_values(colmn, *args)
        val = flag_value_range_for_column(colmn).to_a
        args.each do |flag|
          neg = false
          if flag.to_s.match /^not_/
            neg = true
            flag = flag.to_s.sub(/^not_/, '').to_sym
          end
          check_flag(flag, colmn)
          flag_values = sql_in_for_flag(flag, colmn)
          if neg
            val = val - flag_values
          else
            val = val & flag_values
          end
        end
        val
      end

      def parse_flag_options(*args)
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
        has_ar = (!!defined?(ActiveRecord) && self.respond_to?(:descends_from_active_record?))
        # Supposedly Rails 2.3 takes care of this, but this precaution is needed for backwards compatibility
        has_table = has_ar ? connection.tables.include?(custom_table_name) : true
        if has_table
          found_column = columns.find {|column| column.name == colmn}
          #If you have not yet run the migration that adds the 'flags' column then we don't want to fail, because we need to be able to run the migration
          #If the column is there but is of the wrong type, then we must fail, because flag_shih_tzu will not work
          if found_column.nil?
            warn("Error: Column '#{colmn}' doesn't exist on table '#{custom_table_name}'.  Did you forget to run migrations?")
            return false
          elsif found_column.type != :integer
            raise IncorrectFlagColumnException.new("Table '#{custom_table_name}' must have an integer column named '#{colmn}' in order to use FlagShihTzu.")
          end
        else
          # ActiveRecord gem may not have loaded yet?
          warn("FlagShihTzu#has_flags: Table '#{custom_table_name}' doesn't exist.  Have all migrations been run?") if has_ar
          return false
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
        flag_value_range_for_column(colmn).select {|i| i & val == val}
      end

      def sql_set_for_flag(flag, colmn, enabled = true, custom_table_name = self.table_name)
        check_flag(flag, colmn)
        "#{colmn} = #{colmn} #{enabled ? "| " : "& ~" }#{flag_mapping[colmn][flag]}"
      end

      def is_valid_flag_key(flag_key)
        flag_key > 0 && flag_key == flag_key.to_i
      end

      def is_valid_flag_name(flag_name)
        flag_name.is_a?(Symbol)
      end

      def is_valid_flag_column_name(colmn)
        colmn.is_a?(String)
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

  def set_flags(value, colmn = DEFAULT_COLUMN_NAME)
    self[colmn] = value
  end

  def all_flags(colmn = DEFAULT_COLUMN_NAME)
    flag_mapping[colmn].keys
  end

  def selected_flags(colmn = DEFAULT_COLUMN_NAME)
    all_flags(colmn).map { |flag_name| self.send(flag_name) ? flag_name : nil }.compact
  end

  def select_all_flags(colmn = DEFAULT_COLUMN_NAME)
    all_flags(colmn).each do |flag|
      enable_flag(flag, colmn)
    end
  end

  def unselect_all_flags(colmn = DEFAULT_COLUMN_NAME)
    all_flags(colmn).each do |flag|
      disable_flag(flag, colmn)
    end
  end

  def has_flag?(colmn = DEFAULT_COLUMN_NAME)
    not selected_flags(colmn).empty?
  end

  # returns true if successful
  # third parameter allows you to specify that `self` should also have its in-memory flag attribute updated.
  def update_flag!(flag, value, update_instance = false)
    truthy = FlagShihTzu::TRUE_VALUES.include?(value)
    sql = self.class.set_flag_sql(flag.to_sym, truthy)
    if update_instance
      if truthy
        self.enable_flag(flag)
      else
        self.disable_flag(flag)
      end
    end
    if (ActiveRecord::VERSION::MAJOR <= 3)
      self.class.update_all(sql, self.class.primary_key => id) == 1
    else
      self.class.where("#{self.class.primary_key} = ?", id).update_all(sql) == 1
    end
  end

  private

    def get_bit_for(flag, colmn)
      self.flags(colmn) & self.class.flag_mapping[colmn][flag]
    end

    def determine_flag_colmn_for(flag)
      self.class.determine_flag_colmn_for(flag)
    end

end
