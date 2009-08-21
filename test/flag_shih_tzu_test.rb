require 'test/unit'
require File.expand_path(File.dirname(__FILE__) + '/../lib/flag_shih_tzu')

class FlagColumn
  def name; 'flags'; end
  def type; :integer; end
end

class FlagRecord < Hash
  def self.columns
    [FlagColumn.new]
  end

  def flags=(value)
    self[:flags] = value
  end
end

class Foo < FlagRecord
  def self.table_name
    "foos"
  end
  
  include FlagShihTzu

  has_flags 1 => :deleted,
            2 => :organizer_edited_comment
end




class FlagShihTzuTest < Test::Unit::TestCase
  def test_should_raise_an_exception_when_bit_position_is_negative
    assert_raises ArgumentError do
      eval(<<-EOF
        class Invalid < FlagRecord
          include FlagShihTzu
  
          has_flags({ -1 => :error })
        end
      EOF
      )
    end 
  end

  def setup
    @foo = Foo.new
  end
  
  def test_should_enable_the_flag
    @foo.enable_flag(:deleted)
    assert @foo.flag_enabled?(:deleted)
  end

  def test_should_enable_multiple_flags
    @foo.enable_flag(:deleted)
    @foo.enable_flag(:organizer_edited_comment)
    assert @foo.flag_enabled?(:deleted)
    assert @foo.flag_enabled?(:organizer_edited_comment)
  end

  def test_should_leave_the_flag_enabled_when_called_twice
    2.times do 
      @foo.enable_flag(:deleted)
      assert @foo.flag_enabled?(:deleted)
    end
  end

  def test_should_define_a_deleted_method
    assert_equal false, @foo.deleted
  end

  def test_should_define_a_deleted_predicate
    assert_equal false, @foo.deleted?
  end
  
  def test_should_define_a_deleted=_method
    @foo.deleted = true
    assert @foo.deleted
  end

  def test_should_define_a_deleted_condition_method
    assert_equal "(#{Foo.table_name}.flags & #{Foo.flag_mapping[:deleted]} = 1)", Foo.deleted_condition
  end

  def test_should_define_a_not_deleted_condition_method
    assert_equal "(#{Foo.table_name}.flags & #{Foo.flag_mapping[:deleted]} = 0)", Foo.not_deleted_condition
  end
  
  def test_should_disable_the_flag
    @foo.disable_flag(:deleted)
    assert @foo.flag_disabled?(:deleted)
  end

  def test_should_disable_multiple_flags
    @foo.disable_flag(:deleted)
    @foo.disable_flag(:organizer_edited_comment)
    assert @foo.flag_disabled?(:deleted)
    assert @foo.flag_disabled?(:organizer_edited_comment)
  end

  def test_should_leave_the_flag_disabled_when_called_twice
    2.times do 
      @foo.disable_flag(:deleted)
      assert @foo.flag_disabled?(:deleted)
    end
  end

  def test_should_be_possible_to_query_a_foo_that_has_never_been_set
    assert_equal false, Foo.new.deleted?
  end

  def test_should_return_0_by_default
    foo = Foo.new
    assert foo.flags == 0
  end

  def test_should_have_flag_mapping_for_each_flag
    assert_equal 1, Foo.flag_mapping[:deleted]
    assert_equal 2, Foo.flag_mapping[:organizer_edited_comment]
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