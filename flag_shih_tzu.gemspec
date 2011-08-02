# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "flag_shih_tzu/version"

Gem::Specification.new do |s|
  s.name        = "flag_shih_tzu"
  s.version     = FlagShihTzu::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Patryk Peszko", "Sebastian Roebke", "David Anderson", "Tim Payton"]
  s.homepage    = "https://github.com/xing/flag_shih_tzu"
  s.summary     = %q{A rails plugin to store a collection of boolean attributes in a single ActiveRecord column as a bit field}
  s.description = <<-EODOC
This plugin lets you use a single integer column in an ActiveRecord model
to store a collection of boolean attributes (flags). Each flag can be used
almost in the same way you would use any boolean attribute on an
ActiveRecord object.
  EODOC

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
