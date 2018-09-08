source "http://rubygems.org"

gemspec :path => ".."

gem "activerecord", "~> 4.2.0"
gem "sqlite3", "~> 1.3", :platforms => [:ruby]
gem "activerecord-jdbcsqlite3-adapter", "~> 1.3.23", :platforms => [:jruby]
gem "activerecord-mysql2-adapter", :platforms => [:ruby]
gem "activerecord-jdbcmysql-adapter", "~> 1.3.23", :platforms => [:jruby]
gem "pg", :platforms => [:ruby_18]
gem "activerecord-jdbcpostgresql-adapter", "~> 1.3.23", :platforms => [:jruby]

gem "reek", "~> 3.5.0", :platforms => [:ruby]
gem "roodi", "~> 5.0.0", :platforms => [:ruby]
