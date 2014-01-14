require 'git_tools/branches/cleaner'

namespace :git do
  namespace :branches do
    # puts $VERBOSE, $-V, $DEBUG, $-W
    # VERBOSE and DEBUG mode don't seem to be triggered in rake tasks even with RUBYOPTS.
    # Something turning it off?

    GitTools::Branches::ActionExecutor.test_mode = $DEBUG
    GitTools::Branches::ActionExecutor.skip_prompted = true

    desc 'Clean up all branches'
    task(:clean => ['clean:local', 'clean:remote']) do
    end

    namespace :clean do
      desc 'Clean up local branches'
      task :local do
        GitTools::Branches::Cleaner.with_local('stable').run!
      end

      desc 'Clean up remote branches'
      task :remote do
        # TODO: Handle non origin
        GitTools::Branches::Cleaner.with_origin.run!
      end

    end
  end
end
