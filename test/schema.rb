ActiveRecord::Schema.define(:version => 0) do
  create_table :spaceships, :force => true do |t| 
    t.string :type, :null => false, :default => 'Spaceship'
    t.integer :flags, :null => false, :default => 0
    t.string :incorrect_flags_column, :null => false, :default => ''
  end 

  create_table :spaceships_with_custom_flags_column, :force => true do |t| 
    t.integer :bits, :null => false, :default => 0
  end

  create_table :spaceships_with_2_custom_flags_column, :force => true do |t| 
    t.integer :bits, :null => false, :default => 0
    t.integer :commanders, :null => false, :default => 0
  end

  create_table :spaceships_without_flags_column, :force => true do |t| 
  end

  create_table :spaceships_with_non_integer_column, :force => true do |t| 
    t.string :flags, :null => false, :default => 'A string'
  end
end
