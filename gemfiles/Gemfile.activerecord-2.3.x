source "http://rubygems.org"

gemspec :path => ".."

gem "mime-types", "< 2.0.0", :platforms => [:ruby_18]

gem "activerecord", "~> 2.3.0"
gem "sqlite3", "~> 1.3", :platforms => [:ruby]
gem "activerecord-jdbcsqlite3-adapter", :platforms => [:jruby]
gem "mysql", :platforms => [:ruby_19]
gem "activerecord-mysql2-adapter", :platforms => [:ruby_20]
gem "activerecord-jdbcmysql-adapter", :platforms => [:jruby]
gem "pg", :platforms => [:ruby_18]
gem "activerecord-jdbcpostgresql-adapter", :platforms => [:jruby]
gem "tins", "~> 1.6.0", :platforms => [:ruby_19] # released August 13, 2015
gem "term-ansicolor", "~> 1.3.2", :platforms => [:ruby_19] # released June 23, 2015

gem "rake", "~> 0.9.6"
gem "reek", "~> 2.2.1", :platforms => [:ruby]
gem "roodi", "~> 5.0.0", :platforms => [:ruby]
