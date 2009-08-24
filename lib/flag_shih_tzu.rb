module FlagShihTzu
  TRUE_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE'] # taken from ActiveRecord::ConnectionAdapters::Column
  
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def has_flags(flag_hash, options = {})
      options = {:named_scopes => true, :column => 'flags'}.update(options)
      
      @flag_column = options[:column]
      check_flag_column
      
      @flag_mapping = {}
      
      flag_hash.each do |flag_key, flag_name|
        raise ArgumentError, "has_flags: flag keys should be positive integers, and #{flag_key} is not" unless is_valid_flag_key(flag_key)
        raise ArgumentError, "has_flags: flag names should be symbols, and #{flag_name} is not" unless is_valid_flag_name(flag_name)

        @flag_mapping[flag_name] = 2**(flag_key - 1)

        class_eval <<-EVAL
          def #{flag_name}
            flag_enabled?(:#{flag_name})
          end
          
          def #{flag_name}?
            flag_enabled?(:#{flag_name})
          end
        
          def #{flag_name}=(value)
            FlagShihTzu::TRUE_VALUES.include?(value) ? enable_flag(:#{flag_name}) : disable_flag(:#{flag_name})
          end
          
          def self.#{flag_name}_condition
            sql_condition_for_flag(:#{flag_name}, true)
          end
          
          def self.not_#{flag_name}_condition
            sql_condition_for_flag(:#{flag_name}, false)
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
    
    def flag_column
      @flag_column
    end
    
    def check_flag(flag)
      raise ArgumentError, "Invalid flag '#{flag}'" unless flag_mapping.include?(flag)
    end
    
    
    private 
    
      def check_flag_column
        unless columns.any? { |column| column.name == flag_column && column.type == :integer }
          raise "Table '#{table_name}' must have an integer column named '#{flag_column}' in order to use FlagShihTzu"
        end
      end

      def sql_condition_for_flag(flag, enabled = true)
        check_flag(flag)

        "(#{table_name}.#{flag_column} & #{flag_mapping[flag]} = #{enabled ? '1': '0'})"
      end

      def is_valid_flag_key(flag_key)
        flag_key > 0 && flag_key == flag_key.to_i
      end

      def is_valid_flag_name(flag_name)
        flag_name.is_a?(Symbol)
      end
  end
  
  def enable_flag(flag)
    self.class.check_flag(flag)

    self.flags = self.flags | self.class.flag_mapping[flag]
  end

  def disable_flag(flag)
    self.class.check_flag(flag)

    self.flags = self.flags & ~self.class.flag_mapping[flag]
  end

  def flag_enabled?(flag)
    self.class.check_flag(flag)

    get_bit_for(flag) == 0 ? false : true
  end

  def flag_disabled?(flag)
    self.class.check_flag(flag)

    !flag_enabled?(flag)
  end

  def flags 
    self[self.class.flag_column] || 0
  end

  def flags=(value)
    self[self.class.flag_column] = value
  end


  private 
  
    def get_bit_for(flag)
      self.flags & self.class.flag_mapping[flag]
    end
end
