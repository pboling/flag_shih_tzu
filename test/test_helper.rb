require "test/unit"
require "yaml"
require "logger"
require "flag_shih_tzu"

ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")
ActiveRecord::Migration.verbose = false

configs = YAML.load_file(File.dirname(__FILE__) + "/database.yml")
ActiveRecord::Base.configurations = configs

db_name = ENV["DB"] || "sqlite"
ActiveRecord::Base.establish_connection(db_name)

load(File.dirname(__FILE__) + "/schema.rb")





class Test::Unit::TestCase

	def assert_array_similarity(expected, actual, message=nil)
	  full_message = build_message(message, "<?> expected but was\n<?>.\n", expected, actual)
	  assert_block(full_message) { (expected.size ==  actual.size) && (expected - actual == []) }
	end

end
