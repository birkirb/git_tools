module GitTools
  CUSTOM_DIR = '.git_tools'
end

if defined?(Rake)
  load 'tasks/git_tools/hooks.rake'
  load 'tasks/git_tools/branches.rake'
end
