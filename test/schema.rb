ActiveRecord::Schema.define(:version => 0) do
  create_table :spaceships, :force => true do |t| 
    t.string :type, :null => false, :default => 'Spaceship'
    t.integer :flags, :null => false, :default => 0
  end 
end

ActiveRecord::Schema.define(:version => 0) do
  create_table :spaceships_with_custom_flags_column, :force => true do |t| 
    t.integer :bits, :null => false, :default => 0
  end 
end
