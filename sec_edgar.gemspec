# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "sec_edgar/version"

Gem::Specification.new do |s|
  s.name        = "sec_edgar"
  s.version     = SecEdgar::VERSION
  s.authors     = ["Jim Lindstrom"]
  s.email       = ["jim.lindstrom@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Tools for pulling financial statements out of the SEC Edgar system}
  s.description = %q{Tools for pulling financial statements out of the SEC Edgar system}

  s.rubyforge_project = "sec_edgar"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'rspec-core'
  s.add_dependency 'rspec-mocks'
  s.add_dependency 'rspec-expectations'
  s.add_dependency 'mechanize'
  s.add_dependency 'logger'
  s.add_dependency 'hpricot'
  s.add_dependency 'naive_bayes'
  s.add_dependency 'ruby-stemmer'
  #s.add_dependency 'yahoofinance'
end
