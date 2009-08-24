# FlagShihTzu

This plugin lets you use a single integer column in an ActiveRecord model 
to store a collection of boolean flags. Each flag can be used almost in 
the same way you would use any boolean attribute on an ActiveRecord object.

The main benefit: 
**No migrations needed for new boolean attributes, which means no downtime!**

This is very useful for large tables where adding new columns can take 
a long time or if you just want to avoid adding new columns for every
boolean attribute.

Using FlagShihTzu, you can add new boolean attributes whenever you want, 
without needing any migration. Just change the has_flags call to include 
the new boolean flag. 


## Prerequisites

FlagShihTzu assumes that your ActiveRecord model already has an integer field 
to store the flags, which should be defined to not allow NULL values and 
should have a default value of 0 (which means all flags are initially set to 
false).

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
to enable or disable a flag. The values are symbols for the flags
being created.

The default column name to store the flags is 'flags', but you can provide a 
custom column name using the `:column` option:

    has_flags({ 1 => :warpdrive }, :column => 'bits')


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

The following named scopes become available, too:

    Spaceship.warpdrive         # :conditions => "(spaceships.flags & 1 = 1)"
    Spaceship.not_warpdrive     # :conditions => "(spaceships.flags & 1 = 0)"
    Spaceship.shields           # :conditions => "(spaceships.flags & 2 = 1)"
    Spaceship.not_shields       # :conditions => "(spaceships.flags & 2 = 0)"
    Spaceship.electrolytes      # :conditions => "(spaceships.flags & 4 = 1)"
    Spaceship.not_electrolytes  # :conditions => "(spaceships.flags & 4 = 0)"
    
If you do not want the named scopes to be defined, set the
`:named_scopes` option to false when calling has_flags:
    
    has_flags({ 1 => :warpdrive, 2 => :shields, 3 => :electrolytes }, :named_scopes => false)

Additionally, the following class methods may support you when
manually building ActiveRecord conditions:

    Spaceship.warpdrive_condition         # "(spaceships.flags & 1 = 1)"
    Spaceship.not_warpdrive_condition     # "(spaceships.flags & 1 = 0)"
    Spaceship.shields_condition           # "(spaceships.flags & 2 = 1)"
    Spaceship.not_shields_condition       # "(spaceships.flags & 2 = 0)"
    Spaceship.electrolytes_condition      # "(spaceships.flags & 4 = 1)"
    Spaceship.not_electrolytes_condition  # "(spaceships.flags & 4 = 0)"
  

### Example

    enterprise = Spaceship.new
    enterprise.warpdrive = true
    enterprise.shields = true
    enterprise.electrolytes = false
    enterprise.save
  
    if spaceship.shields?
      ...
    end

    Spaceship.warpdrive.find(:all)
    Spaceship.not_electrolytes.count
    ...


## Running the plugin tests

1. Modify `test/database.yml` to fit your test environment.
2. If needed, create the test database you configured in `database.yml`.

Then you can run 
    
    DB=mysql|postgres|sqlite|sqlite3 rake test:plugins PLUGIN=flag_shih_tzu` 
    
from your Rails project root *or*
    
    DB=mysql|postgres|sqlite|sqlite3 rake 
    
from `vendor/plugins/flag_shih_tzu`.


## Authors

[Patryk Peszko](http://github.com/ppeszko), 
[Sebastian Roebke](http://github.com/boosty), 
[David Anderson](http://github.com/alpinegizmo) 
and [Tim Payton](http://github.com/dizzy42)


## Contributors

[TobiTobes](http://github.com/rngtng)


Copyright (c) 2009 [XING AG](http://www.xing.com/)
Released under the MIT license

Please find out more about our work in our 
[tech blog](http://blog.xing.com/category/english/tech-blog).
