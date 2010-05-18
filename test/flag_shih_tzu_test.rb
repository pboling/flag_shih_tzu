require File.dirname(__FILE__) + '/test_helper.rb'
load_schema

class Spaceship < ActiveRecord::Base
  set_table_name 'spaceships'
  include FlagShihTzu

  has_flags 1 => :warpdrive, 
            2 => :shields, 
            3 => :electrolytes
end

class SpaceshipWithoutNamedScopes < ActiveRecord::Base
  set_table_name 'spaceships'
  include FlagShihTzu

  has_flags(1 => :warpdrive, :named_scopes => false)
end

class SpaceshipWithoutNamedScopesOldStyle < ActiveRecord::Base
  set_table_name 'spaceships'
  include FlagShihTzu

  has_flags({1 => :warpdrive}, :named_scopes => false)
end

class SpaceshipWithCustomFlagsColumn < ActiveRecord::Base
  set_table_name 'spaceships_with_custom_flags_column'
  include FlagShihTzu

  has_flags(1 => :warpdrive, 2 => :hyperspace, :column => 'bits')
end

class SpaceshipWith2CustomFlagsColumn < ActiveRecord::Base
  set_table_name 'spaceships_with_2_custom_flags_column'
  include FlagShihTzu

  has_flags({ 1 => :warpdrive, 2 => :hyperspace }, :column => 'bits')
  has_flags({ 1 => :jeanlucpicard, 2 => :dajanatroj }, :column => 'commanders')
end

class SpaceshipWithBitOperatorQueryMode < ActiveRecord::Base
  set_table_name 'spaceships'
  include FlagShihTzu
  
  has_flags(1 => :warpdrive, 2 => :shields, :flag_query_mode => :bit_operator)
end

class SpaceCarrier < Spaceship
end

# table planets is missing intentionally to see if flagshihtzu handles missing tables gracefully
class Planet < ActiveRecord::Base
end

class FlagShihTzuClassMethodsTest < Test::Unit::TestCase
  
  def setup
    Spaceship.destroy_all
  end

  def test_has_flags_should_raise_an_exception_when_flag_key_is_negative
    assert_raises ArgumentError do
      eval(<<-EOF
        class SpaceshipWithInvalidFlagKey < ActiveRecord::Base
          set_table_name 'spaceships'
          include FlagShihTzu

          has_flags({ -1 => :error })
        end
           EOF
          )
    end
  end

  def test_has_flags_should_raise_an_exception_when_flag_name_already_used
    assert_raises ArgumentError do
      eval(<<-EOF
        class SpaceshipWithAlreadyUsedFlag < ActiveRecord::Base
          set_table_name 'spaceships_with_2_custom_flags_column'
          include FlagShihTzu

          has_flags({ 1 => :jeanluckpicard }, :column => 'bits')
          has_flags({ 1 => :jeanluckpicard }, :column => 'commanders')
        end
           EOF
          )
    end
  end
  
  def test_has_flags_should_raise_an_exception_when_desired_flag_name_method_already_defined
    assert_raises ArgumentError do
      eval(<<-EOF
        class SpaceshipWithAlreadyUsedMethod < ActiveRecord::Base
          set_table_name 'spaceships_with_2_custom_flags_column'
          include FlagShihTzu
          
          def jeanluckpicard; end

          has_flags({ 1 => :jeanluckpicard }, :column => 'bits')
        end
           EOF
          )
    end
  end

  def test_has_flags_should_not_raise_an_exception_when_flag_name_method_defined_by_flagshitzu
    assert_nothing_raised ArgumentError do
      eval(<<-EOF
        class SpaceshipWithAlreadyUsedMethodByFlagshitzu < ActiveRecord::Base
          set_table_name 'spaceships_with_2_custom_flags_column'
          include FlagShihTzu
          
          has_flags({ 1 => :jeanluckpicard }, :column => 'bits')
          has_flags({ 1 => :jeanluckpicard }, :column => 'bits')
        end
           EOF
          )
    end
  end

  def test_has_flags_should_raise_an_exception_when_flag_name_is_not_a_symbol
    assert_raises ArgumentError do
      eval(<<-EOF
        class SpaceshipWithInvalidFlagName < ActiveRecord::Base
          set_table_name 'spaceships'
          include FlagShihTzu

          has_flags({ 1 => 'error' })
        end
           EOF
          )
    end
  end

  def test_should_define_a_sql_condition_method_for_flag_enabled
    assert_equal "(spaceships.flags in (1,3,5,7))", Spaceship.warpdrive_condition
    assert_equal "(spaceships.flags in (2,3,6,7))", Spaceship.shields_condition
    assert_equal "(spaceships.flags in (4,5,6,7))", Spaceship.electrolytes_condition
  end

  def test_should_define_a_sql_condition_method_for_flag_enabled_with_2_colmns
    assert_equal "(spaceships_with_2_custom_flags_column.bits in (1,3))", SpaceshipWith2CustomFlagsColumn.warpdrive_condition
    assert_equal "(spaceships_with_2_custom_flags_column.bits in (2,3))", SpaceshipWith2CustomFlagsColumn.hyperspace_condition
    assert_equal "(spaceships_with_2_custom_flags_column.commanders in (1,3))", SpaceshipWith2CustomFlagsColumn.jeanlucpicard_condition
    assert_equal "(spaceships_with_2_custom_flags_column.commanders in (2,3))", SpaceshipWith2CustomFlagsColumn.dajanatroj_condition
  end

  def test_should_define_a_sql_condition_method_for_flag_not_enabled
    assert_equal "(spaceships.flags not in (1,3,5,7))", Spaceship.not_warpdrive_condition
    assert_equal "(spaceships.flags not in (2,3,6,7))", Spaceship.not_shields_condition
    assert_equal "(spaceships.flags not in (4,5,6,7))", Spaceship.not_electrolytes_condition
  end
  
  def test_should_define_a_sql_condition_method_for_flag_enabled_with_custom_table_name
    assert_equal "(custom_spaceships.flags in (1,3,5,7))", Spaceship.send( :sql_condition_for_flag, :warpdrive, 'flags', true, 'custom_spaceships')
  end  

  def test_should_define_a_sql_condition_method_for_flag_enabled_with_2_colmns_not_enabled
    assert_equal "(spaceships_with_2_custom_flags_column.bits not in (1,3))", SpaceshipWith2CustomFlagsColumn.not_warpdrive_condition
    assert_equal "(spaceships_with_2_custom_flags_column.bits not in (2,3))", SpaceshipWith2CustomFlagsColumn.not_hyperspace_condition
    assert_equal "(spaceships_with_2_custom_flags_column.commanders not in (1,3))", SpaceshipWith2CustomFlagsColumn.not_jeanlucpicard_condition
    assert_equal "(spaceships_with_2_custom_flags_column.commanders not in (2,3))", SpaceshipWith2CustomFlagsColumn.not_dajanatroj_condition
  end
  
  def test_should_define_a_sql_condition_method_for_flag_enabled_using_bit_operators
    assert_equal "(spaceships.flags & 1 = 1)", SpaceshipWithBitOperatorQueryMode.warpdrive_condition
    assert_equal "(spaceships.flags & 2 = 2)", SpaceshipWithBitOperatorQueryMode.shields_condition
  end

  def test_should_define_a_sql_condition_method_for_flag_not_enabled_using_bit_operators
    assert_equal "(spaceships.flags & 1 = 0)", SpaceshipWithBitOperatorQueryMode.not_warpdrive_condition
    assert_equal "(spaceships.flags & 2 = 0)", SpaceshipWithBitOperatorQueryMode.not_shields_condition
  end

  def test_should_define_a_named_scope_for_flag_enabled
    assert_equal({ :conditions => "(spaceships.flags in (1,3,5,7))" }, Spaceship.warpdrive.proxy_options)
    assert_equal({ :conditions => "(spaceships.flags in (2,3,6,7))" }, Spaceship.shields.proxy_options)
    assert_equal({ :conditions => "(spaceships.flags in (4,5,6,7))" }, Spaceship.electrolytes.proxy_options)
  end

  def test_should_define_a_named_scope_for_flag_not_enabled
    assert_equal({ :conditions => "(spaceships.flags not in (1,3,5,7))" }, Spaceship.not_warpdrive.proxy_options)
    assert_equal({ :conditions => "(spaceships.flags not in (2,3,6,7))" }, Spaceship.not_shields.proxy_options)
    assert_equal({ :conditions => "(spaceships.flags not in (4,5,6,7))" }, Spaceship.not_electrolytes.proxy_options)
  end

  def test_should_define_a_named_scope_for_flag_enabled_with_2_columns
    assert_equal({ :conditions => "(spaceships_with_2_custom_flags_column.bits in (1,3))" }, SpaceshipWith2CustomFlagsColumn.warpdrive.proxy_options)
    assert_equal({ :conditions => "(spaceships_with_2_custom_flags_column.bits in (2,3))" }, SpaceshipWith2CustomFlagsColumn.hyperspace.proxy_options)
    assert_equal({ :conditions => "(spaceships_with_2_custom_flags_column.commanders in (1,3))" }, SpaceshipWith2CustomFlagsColumn.jeanlucpicard.proxy_options)
    assert_equal({ :conditions => "(spaceships_with_2_custom_flags_column.commanders in (2,3))" }, SpaceshipWith2CustomFlagsColumn.dajanatroj.proxy_options)
  end

  def test_should_define_a_named_scope_for_flag_not_enabled_with_2_columns
    assert_equal({ :conditions => "(spaceships_with_2_custom_flags_column.bits not in (1,3))" }, SpaceshipWith2CustomFlagsColumn.not_warpdrive.proxy_options)
    assert_equal({ :conditions => "(spaceships_with_2_custom_flags_column.bits not in (2,3))" }, SpaceshipWith2CustomFlagsColumn.not_hyperspace.proxy_options)
    assert_equal({ :conditions => "(spaceships_with_2_custom_flags_column.commanders not in (1,3))" }, SpaceshipWith2CustomFlagsColumn.not_jeanlucpicard.proxy_options)
    assert_equal({ :conditions => "(spaceships_with_2_custom_flags_column.commanders not in (2,3))" }, SpaceshipWith2CustomFlagsColumn.not_dajanatroj.proxy_options)
  end
  
  def test_should_define_a_named_scope_for_flag_enabled_using_bit_operators
    assert_equal({ :conditions => "(spaceships.flags & 1 = 1)" }, SpaceshipWithBitOperatorQueryMode.warpdrive.proxy_options)
    assert_equal({ :conditions => "(spaceships.flags & 2 = 2)" }, SpaceshipWithBitOperatorQueryMode.shields.proxy_options)
  end

  def test_should_define_a_named_scope_for_flag_not_enabled_using_bit_operators
    assert_equal({ :conditions => "(spaceships.flags & 1 = 0)" }, SpaceshipWithBitOperatorQueryMode.not_warpdrive.proxy_options)
    assert_equal({ :conditions => "(spaceships.flags & 2 = 0)" }, SpaceshipWithBitOperatorQueryMode.not_shields.proxy_options)
  end

  def test_should_return_the_correct_number_of_items_from_a_named_scope
    spaceship = Spaceship.new
    spaceship.enable_flag(:warpdrive)
    spaceship.enable_flag(:shields)
    spaceship.save!
    spaceship.reload
    spaceship_2 = Spaceship.new
    spaceship_2.enable_flag(:warpdrive)
    spaceship_2.save!
    spaceship_2.reload
    spaceship_3 = Spaceship.new
    spaceship_3.enable_flag(:shields)
    spaceship_3.save!
    spaceship_3.reload
    assert_equal 1, Spaceship.not_warpdrive.count
    assert_equal 2, Spaceship.warpdrive.count
    assert_equal 1, Spaceship.not_shields.count
    assert_equal 2, Spaceship.shields.count
    assert_equal 1, Spaceship.warpdrive.shields.count
    assert_equal 0, Spaceship.not_warpdrive.not_shields.count
  end

  def test_should_not_define_named_scopes_if_not_wanted
    assert !SpaceshipWithoutNamedScopes.respond_to?(:warpdrive)
    assert !SpaceshipWithoutNamedScopesOldStyle.respond_to?(:warpdrive)
  end

  def test_should_work_with_a_custom_flags_column
    spaceship = SpaceshipWithCustomFlagsColumn.new
    spaceship.enable_flag(:warpdrive)
    spaceship.enable_flag(:hyperspace)
    spaceship.save!
    spaceship.reload
    assert_equal 3, spaceship.flags('bits')
    assert_equal "(spaceships_with_custom_flags_column.bits in (1,3))", SpaceshipWithCustomFlagsColumn.warpdrive_condition
    assert_equal "(spaceships_with_custom_flags_column.bits not in (1,3))", SpaceshipWithCustomFlagsColumn.not_warpdrive_condition
    assert_equal "(spaceships_with_custom_flags_column.bits in (2,3))", SpaceshipWithCustomFlagsColumn.hyperspace_condition
    assert_equal "(spaceships_with_custom_flags_column.bits not in (2,3))", SpaceshipWithCustomFlagsColumn.not_hyperspace_condition
    assert_equal({ :conditions => "(spaceships_with_custom_flags_column.bits in (1,3))" }, SpaceshipWithCustomFlagsColumn.warpdrive.proxy_options)
    assert_equal({ :conditions => "(spaceships_with_custom_flags_column.bits not in (1,3))" }, SpaceshipWithCustomFlagsColumn.not_warpdrive.proxy_options)
    assert_equal({ :conditions => "(spaceships_with_custom_flags_column.bits in (2,3))" }, SpaceshipWithCustomFlagsColumn.hyperspace.proxy_options)
    assert_equal({ :conditions => "(spaceships_with_custom_flags_column.bits not in (2,3))" }, SpaceshipWithCustomFlagsColumn.not_hyperspace.proxy_options)
  end
  
  def test_should_not_error_out_when_table_is_not_present
    assert_nothing_raised(ActiveRecord::StatementInvalid) do
      Planet.class_eval do
        include FlagShihTzu
        has_flags(1 => :habitable)
      end
    end
  end
  
end

class FlagShihTzuInstanceMethodsTest < Test::Unit::TestCase

  def setup
    @spaceship = Spaceship.new
    @big_spaceship = SpaceshipWith2CustomFlagsColumn.new
  end

  def test_should_enable_flag
    @spaceship.enable_flag(:warpdrive)
    assert @spaceship.flag_enabled?(:warpdrive)
  end

  def test_should_enable_flag_with_2_columns
    @big_spaceship.enable_flag(:warpdrive)
    assert @big_spaceship.flag_enabled?(:warpdrive)
    @big_spaceship.enable_flag(:jeanlucpicard)
    assert @big_spaceship.flag_enabled?(:jeanlucpicard)
  end

  def test_should_disable_flag
    @spaceship.enable_flag(:warpdrive)
    assert @spaceship.flag_enabled?(:warpdrive)

    @spaceship.disable_flag(:warpdrive)
    assert @spaceship.flag_disabled?(:warpdrive)
  end

  def test_should_disable_flag_with_2_columns
    @big_spaceship.enable_flag(:warpdrive)
    assert @big_spaceship.flag_enabled?(:warpdrive)
    @big_spaceship.enable_flag(:jeanlucpicard)
    assert @big_spaceship.flag_enabled?(:jeanlucpicard)

    @big_spaceship.disable_flag(:warpdrive)
    assert @big_spaceship.flag_disabled?(:warpdrive)
    @big_spaceship.disable_flag(:jeanlucpicard)
    assert @big_spaceship.flag_disabled?(:jeanlucpicard)
  end

  def test_should_store_the_flags_correctly
    @spaceship.enable_flag(:warpdrive)
    @spaceship.disable_flag(:shields)
    @spaceship.enable_flag(:electrolytes)

    @spaceship.save!
    @spaceship.reload

    assert_equal 5, @spaceship.flags
    assert @spaceship.flag_enabled?(:warpdrive)
    assert !@spaceship.flag_enabled?(:shields)
    assert @spaceship.flag_enabled?(:electrolytes)
  end

  def test_should_store_the_flags_correctly_wiht_2_colmns
    @big_spaceship.enable_flag(:warpdrive)
    @big_spaceship.disable_flag(:hyperspace)
    @big_spaceship.enable_flag(:dajanatroj)

    @big_spaceship.save!
    @big_spaceship.reload

    assert_equal 1, @big_spaceship.flags('bits')
    assert_equal 2, @big_spaceship.flags('commanders')

    assert @big_spaceship.flag_enabled?(:warpdrive)
    assert !@big_spaceship.flag_enabled?(:hyperspace)
    assert @big_spaceship.flag_enabled?(:dajanatroj)
  end

  def test_enable_flag_should_leave_the_flag_enabled_when_called_twice
    2.times do
      @spaceship.enable_flag(:warpdrive)
      assert @spaceship.flag_enabled?(:warpdrive)
    end
  end

  def test_disable_flag_should_leave_the_flag_disabled_when_called_twice
    2.times do
      @spaceship.disable_flag(:warpdrive)
      assert !@spaceship.flag_enabled?(:warpdrive)
    end
  end

  def test_should_define_an_attribute_reader_method
    assert_equal false, @spaceship.warpdrive
  end

  def test_should_define_an_attribute_reader_predicate_method
    assert_equal false, @spaceship.warpdrive?
  end

  def test_should_define_an_attribute_writer_method
    @spaceship.warpdrive = true
    assert @spaceship.warpdrive
  end

  def test_should_respect_true_values_like_active_record
    [true, 1, '1', 't', 'T', 'true', 'TRUE'].each do |true_value|
      @spaceship.warpdrive = true_value
      assert @spaceship.warpdrive
    end

    [false, 0, '0', 'f', 'F', 'false', 'FALSE'].each do |false_value|
      @spaceship.warpdrive = false_value
      assert !@spaceship.warpdrive
    end
  end
  
  def test_should_ignore_has_flags_call_if_column_does_not_exist_yet
    assert_nothing_raised do
      eval(<<-EOF
        class SpaceshipWithoutFlagsColumn < ActiveRecord::Base
          set_table_name 'spaceships_without_flags_column'
          include FlagShihTzu

          has_flags 1 => :warpdrive,
                    2 => :shields,
                    3 => :electrolytes
        end
      EOF
      )
    end
    
    assert !SpaceshipWithoutFlagsColumn.method_defined?(:warpdrive)
  end
  
  def test_should_ignore_has_flags_call_if_column_not_integer
    assert_raises FlagShihTzu::IncorrectFlagColumnException do
      eval(<<-EOF
        class SpaceshipWithNonIntegerColumn < ActiveRecord::Base
          set_table_name 'spaceships_with_non_integer_column'
          include FlagShihTzu

          has_flags 1 => :warpdrive,
                    2 => :shields,
                    3 => :electrolytes
        end
      EOF
      )
    end

    assert !SpaceshipWithoutFlagsColumn.method_defined?(:warpdrive)
  end

  def test_column_guessing_for_default_column
    assert_equal 'flags', @spaceship.send(:determine_flag_colmn_for, :warpdrive)
  end

  def test_column_guessing_for_default_column
    assert_raises FlagShihTzu::NoSuchFlagException do
      @spaceship.send(:determine_flag_colmn_for, :xxx)
    end
  end

  def test_column_guessing_for_2_columns
    assert_equal 'commanders', @big_spaceship.send(:determine_flag_colmn_for, :jeanlucpicard)
    assert_equal 'bits', @big_spaceship.send(:determine_flag_colmn_for, :warpdrive)
  end

end

class FlagShihTzuDerivedClassTest < Test::Unit::TestCase

  def setup
    @spaceship = SpaceCarrier.new
  end

  def test_should_enable_flag
    @spaceship.enable_flag(:warpdrive)
    assert @spaceship.flag_enabled?(:warpdrive)
  end

  def test_should_disable_flag
    @spaceship.enable_flag(:warpdrive)
    assert @spaceship.flag_enabled?(:warpdrive)

    @spaceship.disable_flag(:warpdrive)
    assert @spaceship.flag_disabled?(:warpdrive)
  end

  def test_should_store_the_flags_correctly
    @spaceship.enable_flag(:warpdrive)
    @spaceship.disable_flag(:shields)
    @spaceship.enable_flag(:electrolytes)

    @spaceship.save!
    @spaceship.reload

    assert_equal 5, @spaceship.flags
    assert @spaceship.flag_enabled?(:warpdrive)
    assert !@spaceship.flag_enabled?(:shields)
    assert @spaceship.flag_enabled?(:electrolytes)
  end

  def test_enable_flag_should_leave_the_flag_enabled_when_called_twice
    2.times do 
      @spaceship.enable_flag(:warpdrive)
      assert @spaceship.flag_enabled?(:warpdrive)
    end
  end

  def test_disable_flag_should_leave_the_flag_disabled_when_called_twice
    2.times do 
      @spaceship.disable_flag(:warpdrive)
      assert !@spaceship.flag_enabled?(:warpdrive)
    end
  end

  def test_should_define_an_attribute_reader_method
    assert_equal false, @spaceship.warpdrive?
  end

  def test_should_define_an_attribute_writer_method
    @spaceship.warpdrive = true
    assert @spaceship.warpdrive
  end

  def test_should_respect_true_values_like_active_record
    [true, 1, '1', 't', 'T', 'true', 'TRUE'].each do |true_value|
      @spaceship.warpdrive = true_value
      assert @spaceship.warpdrive
    end

    [false, 0, '0', 'f', 'F', 'false', 'FALSE'].each do |false_value|
      @spaceship.warpdrive = false_value
      assert !@spaceship.warpdrive
    end
  end
end
