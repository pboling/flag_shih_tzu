# FlagShihTzu_Ternary_flag_update

## Summary

The updated functionality of the gem allow flag(s) to be set as nil, i.e neither true nor false.


### Defaults (Important)

* As, the rails default limit(size) of an integer is 4, the ternary update restricts the support of total no. of flags to 15. Change the limit value in the migration to increase total no. of flags.
* Due to the default of `0`, *all flags* are initially set to "false". To set all flags to nil initially, assign default value to 2^(32-1)-1 i.e 2147483647 in the migration.


### Bit Fields: How it stores the three values

As said, FlagShihTzu uses a single integer column to store the values for all
the defined flags as a [bit field][bitfield].

So, to accomodate 3 values(true, false and nil), a combination of 2 bits is used to store one of the three value via following mapping:

		 `---+---+---+---+
		 | Value | Bits  |
		 |       |       |
		 `---+---+---+---+
		 | false |  00   |
		 `---+---+---+---+
		 | true  |  10   |
		 `---+---+---+---+
		 | nil   |  11   |
		 `---+---+---+---+

The bit position of a flag corresponds to the given key.

This way, we can use [bitwise operators][bit_operation] on the stored integer value to set, unset
and check individual flags.

                  `---+---+---+---+---+---+                       +---+---+---+---+---+---`
                  |       |       |       |                       |       |       |       |
    Flag position |   3   |   2   |   1   |                       |   3   |   2   |   1   |
    (flag key)    |       |       |       |                       |       |       |       |
                  `---+---+---+---+---+---+                       +---+---+---+---+---+---`
                  |   e   |   s   |   w   |                       |   e   |   s   |   w   |
                  |   l   |   h   |   a   |                       |   l   |   h   |   a   |
                  |   e   |   i   |   r   |                       |   e   |   i   |   r   |
                  |   c   |   e   |   p   |                       |   c   |   e   |   p   |
                  |   t   |   l   |   d   |                       |   t   |   l   |   d   |
                  |   r   |   d   |   r   |                       |   r   |   d   |   r   |
                  |   o   |   s   |   i   |                       |   o   |   s   |   i   |
                  |   l   |       |   v   |                       |   l   |       |   v   |
                  |   y   |       |   e   |                       |   y   |       |   e   |
                  |   t   |       |       |                       |   t   |       |       |
                  |   e   |       |       |                       |   e   |       |       |
                  |   s   |       |       |                       |   s   |       |       |
                  `---+---+---+---+---+---+                       +---+---+---+---+---+---`
	           | true  | false |  nil  |                       |  nil  | true  | false |
    Flag Value    `---+---|---+---|---+---+                       +---+---|---+---|---+---`
                  |  0 1  |  0 0  |  1 1  |                       |  1 1  |  0 1  |  0 0  |
                  `---+---+---+---|---+---+                       +---+---|---+---|---+---`
    Bit Value     | 32 16 |  8 4  |  2 1  | = 16 + 2 + 1 = 19     | 32 16 |  8 4  |  2 1  | = 32 + 16 + 4 = 52
                  `---+---+---+---|---+---+                       +---+---|---+---|---+---`
                                            
Read more about [bit fields][bit_field] here: http://en.wikipedia.org/wiki/Bit_field


### Bang Method for nil value

When setting the `:bang_methods` option to true, the following method also gets defined:

    Spaceship#electrolytes_nil!     # will save the bitwise equivalent of electrolytes = nil on the record

which clears the current value of the electrolytes flag.


### Generated named scope for nil flags

The following new named scope(s) become available:

```ruby
Spaceship.warpdrive_nil	    # :conditions => "(spaceships.flags in (3,7,11,15,19,23,27,31,35,39,43,47,51,55,59,63,67,71,75,79,83,87,91,95))"
```


### Support for manually building conditions

The following class method gets added for nil condition for supporting manually building
ActiveRecord conditions:

```ruby
Spaceship.warpdrive_nil_condition	    # :conditions => "(spaceships.flags in (3,7,11,15,19,23,27,31,35,39,43,47,51,55,59,63,67,71,75,79,83,87,91,95))"
```


### Query mode

While the default way of building the SQL conditions uses an `IN()` list
(as shown above) and the same is also used in flag_shih_tzu, this approach will not work well in this gem for higher number of flags,
as the value list for `IN()` grows a lot faster.

So, in this gem, flag query mode is changed to `:bit_operator`
from `:in_list`

This will modify the generated condition and named_scope methods to use bit
operators in the SQL instead of an `IN()` list:

```ruby
Spaceship.warpdrive_condition         # "(spaceships.flags & 3 = 1)",
Spaceship.not_warpdrive_condition     # "(spaceships.flags & 3 = 0)",
Spaceship.warpdrive_nil_condition     # "(spaceships.flags & 3 = 3)",
Spaceship.shields_condition           # "(spaceships.flags & 12 = 4)",
Spaceship.not_shields_condition       # "(spaceships.flags & 12 = 0)",
Spaceship.shields_nil_condition       # "(spaceships.flags & 12 = 12)",

Spaceship.warpdrive     	      # :conditions => "(spaceships.flags & 3 = 1)"
Spaceship.not_warpdrive 	      # :conditions => "(spaceships.flags & 3 = 0)"
Spaceship.warpdrive_nil               # :conditions => "(spaceships.flags & 3 = 3)"
Spaceship.shields                     # :conditions => "(spaceships.flags & 12 = 4)"
Spaceship.not_shields                 # :conditions => "(spaceships.flags & 12 = 0)"
Spaceship.shields_nil                 # :conditions => "(spaceships.flags & 12 = 12)"
```
