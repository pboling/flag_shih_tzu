require "test/unit"
require "yaml"
require "logger"
require "flag_shih_tzu"

ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")

configs = YAML.load_file(File.dirname(__FILE__) + "/database.yml")
ActiveRecord::Base.configurations = configs

db_name = ENV["DB"] || "sqlite"
ActiveRecord::Base.establish_connection(db_name)

load(File.dirname(__FILE__) + "/schema.rb")
