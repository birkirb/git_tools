# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "git_tools"
  s.version     = '0.2.1'
  s.authors     = ["Birkir A. Barkarson"]
  s.email       = ["birkirb@stoicviking.net"]
  s.licenses    = ['MIT']
  s.homepage    = "https://github.com/birkirb/git_tools"
  s.summary     = %q{Collection of various handy git commands and tasks.}
  s.description = %q{Git tools for installing hooks, cleaning up branches and more.}

  s.rubyforge_project = "git_tools"

  s.add_runtime_dependency("docopt")
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
