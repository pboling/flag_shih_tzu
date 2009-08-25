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

  has_flags({ 1 => :warpdrive }, :named_scopes => false)
end

class SpaceshipWithCustomFlagsColumn < ActiveRecord::Base
  set_table_name 'spaceships_with_custom_flags_column'
  include FlagShihTzu

  has_flags({ 1 => :warpdrive }, :column => 'bits')
end


class FlagShihTzuClassMethodsTest < Test::Unit::TestCase
  
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
    assert_equal "(spaceships.flags & 1 = 1)", Spaceship.warpdrive_condition
    assert_equal "(spaceships.flags & 2 = 1)", Spaceship.shields_condition
    assert_equal "(spaceships.flags & 4 = 1)", Spaceship.electrolytes_condition
  end

  def test_should_define_a_sql_condition_method_for_flag_not_enabled
    assert_equal "(spaceships.flags & 1 = 0)", Spaceship.not_warpdrive_condition
    assert_equal "(spaceships.flags & 2 = 0)", Spaceship.not_shields_condition
    assert_equal "(spaceships.flags & 4 = 0)", Spaceship.not_electrolytes_condition
  end
  
  def test_should_define_a_named_scope_for_flag_enabled
    expected_options = { :conditions => "(spaceships.flags & 1 = 1)" }
    assert_equal expected_options, Spaceship.warpdrive.proxy_options
  end
  
  def test_should_define_a_named_scope_for_flag_not_enabled
    expected_options = { :conditions => "(spaceships.flags & 1 = 0)" }
    assert_equal expected_options, Spaceship.not_warpdrive.proxy_options
  end
  
  def test_should_not_define_named_scopes_if_not_wanted
    assert !SpaceshipWithoutNamedScopes.respond_to?(:warpdrive)
  end
  
  def test_should_work_with_a_custom_flags_column
    spaceship = SpaceshipWithCustomFlagsColumn.new
    spaceship.enable_flag(:warpdrive)
    spaceship.save!
    spaceship.reload
    assert 1, spaceship.flags
    assert_equal "(spaceships_with_custom_flags_column.bits & 1 = 1)", SpaceshipWithCustomFlagsColumn.warpdrive_condition
    assert_equal "(spaceships_with_custom_flags_column.bits & 1 = 0)", SpaceshipWithCustomFlagsColumn.not_warpdrive_condition
    assert_equal({ :conditions => "(spaceships_with_custom_flags_column.bits & 1 = 1)" }, SpaceshipWithCustomFlagsColumn.warpdrive.proxy_options)
    assert_equal({ :conditions => "(spaceships_with_custom_flags_column.bits & 1 = 0)" }, SpaceshipWithCustomFlagsColumn.not_warpdrive.proxy_options)
  end
  
end


class FlagShihTzuInstanceMethodsTest < Test::Unit::TestCase
  
  def setup
    @spaceship = Spaceship.new
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
  
  def should_store_the_flags_correctly
    @spaceship.enable_flag(:warpdrive)
    @spaceship.disable_flag(:shields)
    @spaceship.enable_flag(:electrolytes)

    @spaceship.save!
    @spaceship.reload

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

  def test_should_respect_value_as_string
    @foo.deleted = "true"
    assert @foo.deleted

    @foo.deleted = "false"
    assert !@foo.deleted

    @foo.deleted = "1"
    assert @foo.deleted

    @foo.deleted = "0"
    assert !@foo.deleted
  end

end