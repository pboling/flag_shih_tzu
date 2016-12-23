source "http://rubygems.org"

gemspec :path => ".."

gem "activerecord", "~> 5.0.0"
gem "sqlite3", "~> 1.3", :platforms => [:ruby]
gem "activerecord-jdbcsqlite3-adapter", :platforms => [:jruby]
gem "activerecord-mysql2-adapter", :platforms => [:ruby]
gem "activerecord-jdbcmysql-adapter", :platforms => [:jruby]
gem "pg", :platforms => [:ruby_18]
gem "activerecord-jdbcpostgresql-adapter", :platforms => [:jruby]

gem "reek", "~> 3.5.0", :platforms => [:ruby]
gem "roodi", "~> 5.0.0", :platforms => [:ruby]
