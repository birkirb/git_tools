require 'git_tools/hooks'

namespace :git do
  namespace :hooks do
    desc "Clear any installed git-hooks"
    task :clear do
      GitTools::Hooks.clear_git_hooks
    end

    desc "Install all git-hooks"
    task :install do
      GitTools::Hooks.install_git_hooks
    end

    desc "Re-install all git-hooks"
    task :reinstall do
      GitTools::Hooks.clear_git_hooks
      GitTools::Hooks.install_git_hooks
    end
  end
end
