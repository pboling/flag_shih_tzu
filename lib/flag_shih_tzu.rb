module FlagShihTzu
  TRUE_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE'] #taken from ActiveRecord::ConnectionAdapters::Column
  
  def self.included(base)
    base.extend(ClassMethods)
    unless base.columns.any? { |column| column.name == 'flags' && column.type == :integer }
      raise "#{base} must have an integer column named 'flags' in order to use FlagShihTzu"
    end
  end

  module ClassMethods
    def has_flags(flag_hash)
      @flag_mapping = {}
      
      flag_hash.each do |flag_key, flag_name|
        raise ArgumentError, "has_flags: keys should be positive integers, and #{flag_key} is not" unless is_valid_flag_key(flag_key)

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
      end
    end

    def flag_mapping
      @flag_mapping
    end
    
    def check_flag(flag)
      raise ArgumentError, "Invalid flag '#{flag}'" unless flag_mapping.include?(flag)
    end

    private 
      def sql_condition_for_flag(flag, enabled = true)
        check_flag(flag)

        "(#{table_name}.flags & #{flag_mapping[flag]} = #{enabled ? '1': '0'})"
      end

      def is_valid_flag_key(flag_key)
        flag_key > 0 && flag_key == flag_key.to_i
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
    self[:flags] || 0
  end

  private 
  
    def get_bit_for(flag)
      self.flags & self.class.flag_mapping[flag]
    end
end
