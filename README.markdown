# FlagShihTzu

This plugin lets you use a single integer field in an ActiveRecord model 
to store a collection of boolean flags. Each flag can be used almost in 
the same way you would use any boolean attribute on an ActiveRecord object.

The main benefit: 
**No migrations needed for new boolean fields, which means no downtime!**

This is very useful for large tables where adding new columns can take 
a long time.

Using FlagShihTzu, you can add new boolean fields whenever you want, 
without needing any migration, just change the has_flags call to include 
the new boolean flag. 


## Prerequisites

FlagShihTzu assumes that your ActiveRecord model already has an integer field 
named flags, which should be defined to not allow NULL values and should have 
a default value of 0 (which means all flags are initially set to false).

The plugin has been tested with Rails versions from 2.1 to 2.3 and MySQL.


## Installation

    cd path/to/your/rails-project
    ./script/plugin install git://github.com/xing/flag_shih_tzu.git


## Usage

    class Spaceship < ActiveRecord::Base
      include FlagShihTzu

      has_flags 1 => :warpdrive,
                2 => :shields,
                3 => :electrolytes

    end

`has_flags` takes a hash. The keys must be positive integers and should not 
be changed once in use, as they represent the position of the bit being used 
to enable or disable a flag. The values are symbols for the attributes 
being created. 

Calling `has_flags` as shown above creates the following instance methods 
on Spaceship:

    Spaceship#warpdrive
    Spaceship#warpdrive?
    Spaceship#warpdrive=
    Spaceship#shields
    Spaceship#shields?
    Spaceship#shields=
    Spaceship#electrolytes
    Spaceship#electrolytes?
    Spaceship#electrolytes=

Additionally, the following class method on Spaceship will support you in 
building ActiveRecord conditions:

    Spaceship.electrolytes_condition      # => "(spaceships.flags & 4 = 1)"
    Spaceship.not_electrolytes_condition  # => "(spaceships.flags & 4 = 0)"
  
and provides you named routes `flagged` or `not_flagged` with the flag name as argument:

    Spaceship.flagged(:electrolytes).all
    Spaceship.not_flagged(:electrolytes).all


### Example

    enterprise = Spaceship.new
    enterprise.warpdrive = true
    enterprise.shields = true
    enterprise.electrolytes = false
    enterprise.save
  
    if spaceship.shields?
      ...
    end

    spaceships_with_electrolytes = Spaceship.find(:all, 
      :conditions => Spaceship.electrolytes_condition)
      
    spaceships_without_electrolytes = Spaceship.find(:all, 
      :conditions => Spaceship.not_electrolytes_condition)

    Spaceship.flagged(:warpdrive).not_flagged(:shields).all


## Authors

[Patryk Peszko](http://github.com/ppeszko), 
[Sebastian Roebke](http://github.com/boosty), 
[David Anderson](http://github.com/alpinegizmo) 
and [Tim Payton](http://github.com/dizzy42)

Copyright (c) 2009 [XING AG](http://www.xing.com/)
Released under the MIT license

Please find out more about our work in our 
[tech blog](http://blog.xing.com/category/english/tech-blog).
