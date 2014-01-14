module GitTools
  module Hooks
    GIT_HOOK_INSTALL_LINE_BEGIN = "# BEGIN Ruby git-hooks\n"
    GIT_HOOK_INSTALL_LINE_END = "# END Ruby git-hooks\n"
    RUBY_HOOK_DIR = File.join(File.dirname(__FILE__), 'hooks')

    def self.with_git_hook_files
      git_hook_dir = File.join('.git', 'hooks')
      puts "HOOK DIR #{git_hook_dir}"
      if File.exist?(git_hook_dir)
        ruby_hooks.each do |prefix|
          hook_file = File.join(git_hook_dir, prefix)
          yield(prefix, hook_file)
        end
      else
        puts "Git hook directory not found."
      end
    end

    def self.ruby_hooks
      Dir.entries(RUBY_HOOK_DIR) - ['.', '..']
    end

    def self.clear_git_hooks
      with_git_hook_files do |prefix, hook_file|
        if File.exists?(hook_file)
          hook_content = File.read(hook_file)
          if hook_content.match(/#{GIT_HOOK_INSTALL_LINE_BEGIN}/)
            puts "Clearing Ruby #{prefix} git-hooks."
            hook_content.gsub!(/#{GIT_HOOK_INSTALL_LINE_BEGIN}.*#{GIT_HOOK_INSTALL_LINE_END}/m, '')
            File.open(hook_file, 'w+') do |file|
              file.write(hook_content)
            end
          end
        end
      end
    end

    def self.install_git_hooks
      with_git_hook_files do |prefix, hook_file|
        if File.exists?(hook_file)
          hook_content = File.read(hook_file)
        else
          hook_content = "#!/bin/sh\n\n"
        end

        if hook_content.match(/#{GIT_HOOK_INSTALL_LINE_BEGIN}/)
          next
        else
          puts "Installing Ruby #{prefix} git-hooks."
          hook_commands = ''
          hook_files = File.join(RUBY_HOOK_DIR, prefix)
          Dir.foreach(hook_files) do |file_path|
            if file_path.match(/\.rb$/)
              hook_commands += "if [ $? -eq 0 ]; then ruby #{File.join(RUBY_HOOK_DIR, prefix, file_path)} \"$@\"; else exit 1; fi\n"
            end
          end
          hook_content += "#{GIT_HOOK_INSTALL_LINE_BEGIN}\n#{hook_commands}\n#{GIT_HOOK_INSTALL_LINE_END}"
          File.open(hook_file, 'w+') do |file|
            file.write(hook_content)
          end
          FileUtils.chmod(0744, hook_file)
        end
      end
    end

  end
end
