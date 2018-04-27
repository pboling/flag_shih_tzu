source "http://rubygems.org"

gemspec :path => ".."

gem "activerecord", "~> 5.2.0"
gem "sqlite3", "~> 1.3", :platforms => [:ruby]
gem "activerecord-mysql2-adapter", :platforms => [:ruby]
gem "pg", :platforms => [:ruby_18]

platform :jruby do
  gem 'jdbc-sqlite3',                         github: "jruby/activerecord-jdbc-adapter", branch: 'rails-5'
  gem 'jdbc-mysql',                           github: "jruby/activerecord-jdbc-adapter", branch: 'rails-5'
  gem 'jdbc-postgres',                        github: "jruby/activerecord-jdbc-adapter", branch: 'rails-5'
  gem 'activerecord-jdbc-adapter',            github: "jruby/activerecord-jdbc-adapter", branch: 'rails-5'
  gem "activerecord-jdbcsqlite3-adapter",     github: "jruby/activerecord-jdbc-adapter", branch: 'rails-5'
  gem "activerecord-jdbcmysql-adapter",       github: "jruby/activerecord-jdbc-adapter", branch: 'rails-5'
  gem "activerecord-jdbcpostgresql-adapter",  github: "jruby/activerecord-jdbc-adapter", branch: 'rails-5'
end

gem "reek", "~> 3.5.0", :platforms => [:ruby]
gem "roodi", "~> 5.0.0", :platforms => [:ruby]
