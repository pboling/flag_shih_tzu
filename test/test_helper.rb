require 'rubygems'
require 'test/unit'
require 'yaml'
require 'active_record'

$:.unshift File.join(File.dirname(__FILE__), '../lib')

require 'init'

def load_schema
  config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
  ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")
  db_adapter = ENV['DB'] || 'sqlite3'
  
  # no DB passed, try sqlite3 by default
  db_adapter ||=
    begin
      require 'sqlite3'
        'sqlite3'
    rescue MissingSourceFile 
    end
    
  if db_adapter.nil? 
    raise "No DB Adapter selected. Configure test/database.yml and use DB=mysql|postgresql|sqlite3 to pick one. sqlite3 will be used by default (gem install sqlite3-ruby)."
  end
  
  ActiveRecord::Base.establish_connection(config[db_adapter])
  load(File.dirname(__FILE__) + "/schema.rb")
end
