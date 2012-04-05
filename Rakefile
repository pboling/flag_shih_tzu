require 'rake'
require 'rake/testtask'
require 'rdoc/task'

require 'bundler'
Bundler::GemHelper.install_tasks

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the flag_shih_tzu plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the flag_shih_tzu plugin.'
RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'FlagShihTzu'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

namespace :test do
  desc 'Test against all supported ActiveRecord versions'
  task :all do
    %w(2.3.x 3.0.x 3.1.x 3.2.x).each do |version|
      sh "BUNDLE_GEMFILE='gemfiles/Gemfile.activerecord-#{version}' bundle"
      sh "BUNDLE_GEMFILE='gemfiles/Gemfile.activerecord-#{version}' bundle exec rake test"
    end
  end

  desc 'Measures test coverage'
  task :coverage do
    rm_f "coverage"
    system("rcov -Ilib test/*_test.rb")
    system("open coverage/index.html") if PLATFORM['darwin']
  end
end
