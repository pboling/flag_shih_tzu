# FlagShihTzu

Bit fields for ActiveRecord

| Project                 |  FlagShihTzu      |
|------------------------ | ----------------- |
| gem name                |  flag_shih_tzu    |
| license                 |  MIT              |
| moldiness               |  [![Maintainer Status](http://stillmaintained.com/pboling/flag_shih_tzu.png)](http://stillmaintained.com/pboling/flag_shih_tzu) |
| version                 |  [![Gem Version](https://badge.fury.io/rb/flag_shih_tzu.png)](http://badge.fury.io/rb/flag_shih_tzu) |
| dependencies            |  [![Dependency Status](https://gemnasium.com/pboling/flag_shih_tzu.png)](https://gemnasium.com/pboling/flag_shih_tzu) |
| code quality            |  [![Code Climate](https://codeclimate.com/github/pboling/flag_shih_tzu.png)](https://codeclimate.com/github/pboling/flag_shih_tzu) |
| inline documenation     |  [![Inline docs](http://inch-ci.org/github/pboling/flag_shih_tzu.png)](http://inch-ci.org/github/pboling/flag_shih_tzu) |
| continuous integration  |  [![Build Status](https://secure.travis-ci.org/pboling/flag_shih_tzu.png?branch=master)](https://travis-ci.org/pboling/flag_shih_tzu) |
| test coverage           |  [![Coverage Status](https://coveralls.io/repos/pboling/flag_shih_tzu/badge.png)](https://coveralls.io/r/pboling/flag_shih_tzu) |
| homepage                |  [https://github.com/pboling/flag_shih_tzu][homepage] |
| documentation           |  [http://rdoc.info/github/pboling/flag_shih_tzu/frames][documentation] |
| author                  |  [Peter Boling](https://coderbits.com/pboling) |
| Spread ~♡ⓛⓞⓥⓔ♡~      |  [![Endorse Me](https://api.coderwall.com/pboling/endorsecount.png)](http://coderwall.com/pboling) |

## Summary

An extension for [ActiveRecord](https://rubygems.org/gems/activerecord)
to store a collection of boolean attributes in a single integer column
as a [bit field][bit_field].

This gem lets you use a single integer column in an ActiveRecord model
to store a collection of boolean attributes (flags). Each flag can be used
almost in the same way you would use any boolean attribute on an
ActiveRecord object.

The benefits:

* No migrations needed for new boolean attributes. This helps a lot
  if you have very large db-tables, on which you want to avoid `ALTER TABLE`
  whenever possible.
* Only the one integer column needs to be indexed.
* [Bitwise Operations][bitwise_operation] are fast!

Using FlagShihTzu, you can add new boolean attributes whenever you want,
without needing any migration. Just add a new flag to the `has_flags` call.

What is a ["Shih Tzu"](http://en.wikipedia.org/wiki/Shih_Tzu)?


## Prerequisites

The gem is actively being tested with:

* MySQL, PostgreSQL and SQLite3 databases
* ActiveRecord versions 2.3.x, 3.0.x, 3.1.x, 3.2.x
* Ruby 1.8.7, 1.9.2, 1.9.3, and 2.0.0 (see .travis.yml for the matrix)


## Installation

### Rails 2.x

In environment.rb:

    config.gem 'flag_shih_tzu'

Then:

    $ rake gems:install # use sudo if necessary

### Rails 3

In Gemfile:

    gem 'flag_shih_tzu'

Then:

    $ bundle install


## Usage

FlagShihTzu assumes that your ActiveRecord model already has an [integer field][bit_field]
to store the flags, which should be defined to not allow `NULL` values and
should have a default value of `0`.

### Defaults (Important)

* Due to the default of `0`, *all flags* are initially set to "false").
* For a default of true it will probably be easier in the long run to negate the flag's meaning / name.
** Such as `switched_on` => `switched_off`
* If you **really** want a different, non-zero, default value for a flag column, proceed *adroitly* with a different sql default for the flag column.

### Database Migration

I like to document the intent of the `flags` column in the migration when I can...

    change_table :spaceships do |t|
      t.integer     :flags, :null => false, :default => 0 # flag_shih_tzu-managed bit field
      # Effective booleans which will be stored on the flags column:
      # t.boolean      :warpdrive
      # t.boolean      :shields
      # t.boolean      :electrolytes
    end

### Adding to the Model

    class Spaceship < ActiveRecord::Base
      include FlagShihTzu

      has_flags 1 => :warpdrive,
                2 => :shields,
                3 => :electrolytes
    end

`has_flags` takes a hash. The keys must be positive integers and represent
the position of the bit being used to enable or disable the flag.
**The keys must not be changed once in use, or you will get incorrect results.**
That is why the plugin forces you to set them explicitly.
The values are symbols for the flags being created.


### Bit Fields: How it stores the values

As said, FlagShihTzu uses a single integer column to store the values for all
the defined flags as a [bit field][bitfield].

The bit position of a flag corresponds to the given key.

This way, we can use [bitwise operators][bit_operation] on the stored integer value to set, unset
and check individual flags.

                  `---+---+---+                +---+---+---`
                  |   |   |   |                |   |   |   |
    Bit position  | 3 | 2 | 1 |                | 3 | 2 | 1 |
    (flag key)    |   |   |   |                |   |   |   |
                  `---+---+---+                +---+---+---`
                  |   |   |   |                |   |   |   |
    Bit value     | 4 | 2 | 1 |                | 4 | 2 | 1 |
                  |   |   |   |                |   |   |   |
                  `---+---+---+                +---+---+---`
                  | e | s | w |                | e | s | w |
                  | l | h | a |                | l | h | a |
                  | e | i | r |                | e | i | r |
                  | c | e | p |                | c | e | p |
                  | t | l | d |                | t | l | d |
                  | r | d | r |                | r | d | r |
                  | o | s | i |                | o | s | i |
                  | l |   | v |                | l |   | v |
                  | y |   | e |                | y |   | e |
                  | t |   |   |                | t |   |   |
                  | e |   |   |                | e |   |   |
                  | s |   |   |                | s |   |   |
                  `---+---+---+                +---+---+---`
                  | 1 | 1 | 0 | = 4 ` 2 = 6    | 1 | 0 | 1 | = 4 ` 1 = 5
                  `---+---+---+                +---+---+---`

Read more about [bit fields][bit_field] here: http://en.wikipedia.org/wiki/Bit_field


### Using a custom column name

The default column name to store the flags is `flags`, but you can provide a
custom column name using the `:column` option. This allows you to use
different columns for separate flags:

    has_flags 1 => :warpdrive,
              2 => :shields,
              3 => :electrolytes,
              :column => 'features'

    has_flags 1 => :spock,
              2 => :scott,
              3 => :kirk,
              :column => 'crew'


### Generated boolean patterned instance methods

Calling `has_flags`, as shown above on the 'features' column, creates the following instance methods
on Spaceship:

    Spaceship#warpdrive
    Spaceship#warpdrive?
    Spaceship#warpdrive=
    Spaceship#not_warpdrive
    Spaceship#not_warpdrive?
    Spaceship#not_warpdrive=
    Spaceship#warpdrive_changed?
    Spaceship#all_warpdrives
    Spaceship#selected_warpdrives
    Spaceship#select_all_warpdrives
    Spaceship#unselect_all_warpdrives
    Spaceship#selected_warpdrives=
    Spaceship#has_warpdrive?

    Spaceship#shields
    Spaceship#shields?
    Spaceship#shields=
    Spaceship#not_shields
    Spaceship#not_shields?
    Spaceship#not_shields=
    Spaceship#shields_changed?
    Spaceship#all_shields
    Spaceship#selected_shields
    Spaceship#select_all_shields
    Spaceship#unselect_all_shields
    Spaceship#selected_shields=
    Spaceship#has_shield?

    Spaceship#electrolytes
    Spaceship#electrolytes?
    Spaceship#electrolytes=
    Spaceship#not_electrolytes
    Spaceship#not_electrolytes?
    Spaceship#not_electrolytes=
    Spaceship#electrolytes_changed?
    Spaceship#all_electrolytes
    Spaceship#selected_electrolytes
    Spaceship#select_all_electrolytes
    Spaceship#unselect_all_electrolytes
    Spaceship#selected_electrolytes=
    Spaceship#has_electrolyte?


### Callbacks and Validations

Optionally, you can set the `:bang_methods` option to true to also define the bang methods:

    Spaceship#electrolytes!     # will save the bitwise equivalent of electrolytes = true on the record
    Spaceship#not_electrolytes! # will save the bitwise equivalent of electrolytes = false on the record

which respectively enables or disables the electrolytes flag.

The `:bang_methods` does not save the records to the database, meaning it *cannot* engage validations and callbacks.

Alternatively, if you do want to *save a flag* to the database, while still avoiding validations and callbacks, use `update_flag!` which:

* sets a flag on a database record without triggering callbacks or validations
* optionally syncs the ruby instance with new flag value, by default it does not.


Example:

    update_flag!(flag_name, flag_value, update_instance = false)


### Generated class methods

Calling `has_flags` as shown above creates the following class methods
on Spaceship:

    Spaceship.flag_columns      # [:features, :crew]


### Generated named scopes

The following named scopes become available:

    Spaceship.warpdrive         # :conditions => "(spaceships.flags in (1,3,5,7))"
    Spaceship.not_warpdrive     # :conditions => "(spaceships.flags not in (1,3,5,7))"
    Spaceship.shields           # :conditions => "(spaceships.flags in (2,3,6,7))"
    Spaceship.not_shields       # :conditions => "(spaceships.flags not in (2,3,6,7))"
    Spaceship.electrolytes      # :conditions => "(spaceships.flags in (4,5,6,7))"
    Spaceship.not_electrolytes  # :conditions => "(spaceships.flags not in (4,5,6,7))"

If you do not want the named scopes to be defined, set the
`:named_scopes` option to false when calling `has_flags`:

    has_flags 1 => :warpdrive, 2 => :shields, 3 => :electrolytes, :named_scopes => false

In a Rails 3+ application, FlagShihTzu will use `scope` internally to generate
the scopes. The option on `has_flags` is still named `:named_scopes` however.


### Examples for using the generated methods

    enterprise = Spaceship.new
    enterprise.warpdrive = true
    enterprise.shields = true
    enterprise.electrolytes = false
    enterprise.save

    if enterprise.shields?
      # ...
    end

    Spaceship.warpdrive.find(:all)
    Spaceship.not_electrolytes.count


### Support for manually building conditions

The following class methods may support you when manually building
ActiveRecord conditions:

    Spaceship.warpdrive_condition         # "(spaceships.flags in (1,3,5,7))"
    Spaceship.not_warpdrive_condition     # "(spaceships.flags not in (1,3,5,7))"
    Spaceship.shields_condition           # "(spaceships.flags in (2,3,6,7))"
    Spaceship.not_shields_condition       # "(spaceships.flags not in (2,3,6,7))"
    Spaceship.electrolytes_condition      # "(spaceships.flags in (4,5,6,7))"
    Spaceship.not_electrolytes_condition  # "(spaceships.flags not in (4,5,6,7))"

These methods also accept a `:table_alias` option that can be used when
generating SQL that references the same table more than once:

    Spaceship.shields_condition(:table_alias => 'evil_spaceships') # "(evil_spaceships.flags in (2,3,6,7))"


### Choosing a query mode

While the default way of building the SQL conditions uses an `IN()` list
(as shown above), this approach will not work well for a high number of flags,
as the value list for `IN()` grows.

For MySQL, depending on your MySQL settings, this can even hit the
`max_allowed_packet` limit with the generated query, or the similar query length maximum for PostgreSQL.

In this case, consider changing the flag query mode to `:bit_operator`
instead of `:in_list`, like so:

    has_flags 1 => :warpdrive,
              2 => :shields,
              :flag_query_mode => :bit_operator

This will modify the generated condition and named_scope methods to use bit
operators in the SQL instead of an `IN()` list:

    Spaceship.warpdrive_condition     # "(spaceships.flags & 1 = 1)",
    Spaceship.not_warpdrive_condition # "(spaceships.flags & 1 = 0)",
    Spaceship.shields_condition       # "(spaceships.flags & 2 = 2)",
    Spaceship.not_shields_condition   # "(spaceships.flags & 2 = 0)",

    Spaceship.warpdrive     # :conditions => "(spaceships.flags & 1 = 1)"
    Spaceship.not_warpdrive # :conditions => "(spaceships.flags & 1 = 0)"
    Spaceship.shields       # :conditions => "(spaceships.flags & 2 = 2)"
    Spaceship.not_shields   # :conditions => "(spaceships.flags & 2 = 0)"

The drawback is that due to the [bitwise operation][bitwise_operation] being done on the SQL side,
this query can not use an index on the flags column.

### Updating flag column by raw sql

If you need to do mass updates without initializing object for each row, you can
use `#set_flag_sql` method on your class. Example:

    Spaceship.set_flag_sql(:warpdrive, true) # "flags = flags | 1"
    Spaceship.set_flag_sql(:shields, false)  # "flags = flags & ~2"

And then use it in:

    Spaceship.update_all Spaceship.set_flag_sql(:shields, false)

Beware that using multiple flag manipulation sql statements in the same query
probably will not have the desired effect (at least on sqlite3, not tested
on other databases), so you *should not* do this:

    Spaceship.update_all "#{Spaceship.set_flag_sql(:shields, false)},#{
      Spaceship.set_flag_sql(:warpdrive, true)}"

General rule of thumb: issue only one flag update per update statement.

### Skipping flag column check

By default when you call has_flags in your code it will automatically check
your database to see if you have correct column defined.

Sometimes this may not be a wanted behaviour (e.g. when loading model without
database connection established) so you can set `:check_for_column` option to
false to avoid it.

    has_flags 1 => :warpdrive,
              2 => :shields,
              :check_for_column => false


## Running the gem tests

First, run some infrequent setup:

    $ rvm use 1.9.3
    $ bundle install
    $ BUNDLE_GEMFILE='gemfiles/Gemfile.activerecord-2.3.x' bundle update --quiet
    $ BUNDLE_GEMFILE='gemfiles/Gemfile.activerecord-3.0.x' bundle update --quiet
    $ BUNDLE_GEMFILE='gemfiles/Gemfile.activerecord-3.1.x' bundle update --quiet
    $ BUNDLE_GEMFILE='gemfiles/Gemfile.activerecord-3.2.x' bundle update --quiet
    $ BUNDLE_GEMFILE='gemfiles/Gemfile.activerecord-4.0.x' bundle update --quiet
    $ rvm use 2.1.2
    $ bundle install
    $ BUNDLE_GEMFILE='gemfiles/Gemfile.activerecord-3.2.x' bundle update --quiet
    $ BUNDLE_GEMFILE='gemfiles/Gemfile.activerecord-4.0.x' bundle update --quiet
    $ BUNDLE_GEMFILE='gemfiles/Gemfile.activerecord-4.1.x' bundle update --quiet

Then just:

    $ bundle exec rake test:all

This will internally use rvm and bundler to load specific ActiveRecord versions
before executing the tests (see `gemfiles/`), e.g.:

    $ NOCOVER=true BUNDLE_GEMFILE='gemfiles/Gemfile.activerecord-4.1.x' bundle exec rake test

All tests will use an in-memory sqlite database by default.
If you want to use a different database, see `test/database.yml`,
install the required adapter gem and use the DB environment variable to
specify which config from `test/database.yml` to use, e.g.:

    $ NOCOVER=true DB=mysql bundle exec rake


## Authors

[Peter Boling](http://github.com/pboling),
[Patryk Peszko](http://github.com/ppeszko),
[Sebastian Roebke](http://github.com/boosty),
[David Anderson](http://github.com/alpinegizmo),
[Tim Payton](http://github.com/dizzy42)
and a helpful group of
[contributors](https://github.com/pboling/flag_shih_tzu/contributors).
Thanks!

Find out more about Peter Boling's work
[RailsBling.com](http://railsbling.com/).

Find out more about XING
[Devblog](http://devblog.xing.com/).


## How you can help!

Take a look at the `reek` list, which is the file called `REEK`, and stat fixing things.  Once you complete a change, run the tests.  See "Running the gem tests".

If the tests pass refresh the `reek` list:

    bundle exec rake reek > REEK

Follow the instructions for "Contributing" below.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
6. Create new Pull Request


## Versioning

This library aims to adhere to [Semantic Versioning 2.0.0](http://semver.org/).
Violations of this scheme should be reported as bugs. Specifically,
if a minor or patch version is released that breaks backward
compatibility, a new version should be immediately released that
restores compatibility. Breaking changes to the public API will
only be introduced with new major versions.

As a result of this policy, you can (and should) specify a
dependency on this gem using the [Pessimistic Version Constraint](http://docs.rubygems.org/read/chapter/16#page74) with two digits of precision.

For example:

    spec.add_dependency 'flag_shih_tzu', '~> 4.0'


## 2012 Change of Ownership and 0.3.X Release Notes

FlagShihTzu was originally a [XING AG][http://www.xing.com/] project.  [Peter Boling](http://peterboling.com) was a long time contributor and watcher of the project.
In September 2012 XING transferred ownership of the project to Peter Boling.  Peter Boling had been maintaining a
fork with extended capabilities.  These additional features become a part of the 0.3 line.  The 0.2 line of the gem will
remain true to XING's original.  The 0.3 line aims to maintain complete parity and compatibility with XING's original as
well.  I will continue to monitor other forks for original ideas and improvements. Pull requests are welcome, but please
rebase your work onto the current master to make integration easier.

More information on the changes for 0.3.X: [pboling/flag_shih_tzu/wiki/Changes-for-0.3.x](https://github.com/pboling/flag_shih_tzu/wiki/Changes-for-0.3.x)


## License

MIT License

Copyright (c) 2012-3 [Peter Boling][peterboling] of [RailsBling.com][railsbling]

Copyright (c) 2011 [XING AG](http://www.xing.com/)

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[semver]: http://semver.org/
[pvc]: http://docs.rubygems.org/read/chapter/16#page74
[railsbling]: http://www.railsbling.com
[peterboling]: http://www.peterboling.com
[documentation]: http://rdoc.info/github/pboling/flag_shih_tzu/frames
[homepage]: https://github.com/pboling/flag_shih_tzu
[bit_field]: http://en.wikipedia.org/wiki/Bit_field
[bitwise_operation]: http://en.wikipedia.org/wiki/Bitwise_operation


[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/pboling/flag_shih_tzu/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

