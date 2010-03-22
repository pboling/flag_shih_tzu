ENV['RAILS_ENV'] = 'test'
ENV['RAILS_ROOT'] ||= File.dirname(__FILE__) + '/../../../..'

#exend LOAD_PATH for test with- and without Railsframework
$LOAD_PATH << 'lib/'
$LOAD_PATH << 'vendor/plugins/flag_shih_tzu/lib/'

require 'test/unit'
require 'yaml'
require 'rubygems'
gem 'activerecord', '~> 2.0'
require 'active_record'
require 'flag_shih_tzu' 

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
