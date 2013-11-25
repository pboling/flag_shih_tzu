# -*- encoding: utf-8 -*-
require File.expand_path('../lib/flag_shih_tzu/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = "flag_shih_tzu"
  s.version     = FlagShihTzu::VERSION
  s.licenses    = ['MIT']
  s.email       = 'peter.boling@gmail.com'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Peter Boling", "Patryk Peszko", "Sebastian Roebke", "David Anderson", "Tim Payton"]
  s.homepage    = "https://github.com/pboling/flag_shih_tzu"
  s.summary     = %q{Bit fields for ActiveRecord}
  s.description = <<-EODOC
Bit fields for ActiveRecord:
This gem lets you use a single integer column in an ActiveRecord model
to store a collection of boolean attributes (flags). Each flag can be used
almost in the same way you would use any boolean attribute on an
ActiveRecord object.
  EODOC

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "activerecord", ">= 2.3.0"

  s.add_development_dependency "bundler"
  s.add_development_dependency "rdoc", ">= 2.4.2"
  s.add_development_dependency(%q<reek>, [">= 1.2.8"])
  s.add_development_dependency(%q<roodi>, [">= 2.1.0"])
  s.add_development_dependency "rake"
  s.add_development_dependency "coveralls"
  s.add_development_dependency "sqlite3"
end
