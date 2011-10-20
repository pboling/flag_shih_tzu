# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "flag_shih_tzu/version"

Gem::Specification.new do |s|
  s.name        = "xing-flag_shih_tzu"
  s.version     = FlagShihTzu::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Patryk Peszko", "Sebastian Roebke", "David Anderson", "Tim Payton"]
  s.homepage    = "https://github.com/xing/flag_shih_tzu"
  s.summary     = %q{Bitfields for ActiveRecord}
  s.description = <<-EODOC
This gem lets you use a single integer column in an ActiveRecord model
to store a collection of boolean attributes (flags). Each flag can be used
almost in the same way you would use any boolean attribute on an
ActiveRecord object.
  EODOC

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "activerecord", ">= 2.3.0"

  s.add_development_dependency "bundler"
  s.add_development_dependency "rdoc", ">= 2.4.2"
  s.add_development_dependency "rake"
  s.add_development_dependency "rcov"
  s.add_development_dependency "sqlite3"
end
