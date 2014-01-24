require 'rake'

namespace :gem do
  desc 'Build the gem'
  task :build do
    `mkdir -p pkg`
    `gem build *.gemspec`
    `mv *.gem pkg/`
  end 

  desc 'Publish the gem'
  task :publish do
    gem = `ls pkg | sort | tail -n 1`
    exec("gem push pkg/#{gem}")
  end 

  desc 'Install the gem locally'
  task :install => :build do
    gem = `ls pkg`.split.sort
    puts `gem install pkg/#{gem.last}`
  end 
end

desc 'Remove generated files'
task :clean do
  `rm -rf pkg`
end
