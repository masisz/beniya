# frozen_string_literal: true

module Beniya
  class FileOpener
    def initialize
      @config_loader = ConfigLoader
    end

    def open_file(file_path)
      return false unless File.exist?(file_path)
      return false if File.directory?(file_path)

      application = find_application_for_file(file_path)
      execute_command(application, file_path)
    end

    def open_file_with_line(file_path, line_number)
      return false unless File.exist?(file_path)
      return false if File.directory?(file_path)

      application = find_application_for_file(file_path)
      execute_command_with_line(application, file_path, line_number)
    end

    private

    def find_application_for_file(file_path)
      extension = File.extname(file_path).downcase.sub('.', '')
      applications = @config_loader.applications

      applications.each do |extensions, app|
        return app if extensions.is_a?(Array) && extensions.include?(extension)
      end

      applications[:default] || 'open'
    end

    def execute_command(application, file_path)
      quoted_path = quote_shell_argument(file_path)

      case RbConfig::CONFIG['host_os']
      when /mswin|mingw|cygwin/
        # Windows
        system("start \"\" \"#{file_path}\"")
      when /darwin/
        # macOS
        if application == 'open'
          system("open #{quoted_path}")
        else
          # VSCodeなど特定のアプリケーション
          system("#{application} #{quoted_path}")
        end
      else
        # Linux/Unix
        if application == 'open'
          system("xdg-open #{quoted_path}")
        else
          system("#{application} #{quoted_path}")
        end
      end
    rescue StandardError => e
      warn "ファイルを開けませんでした: #{e.message}"
      false
    end

    def execute_command_with_line(application, file_path, line_number)
      quoted_path = quote_shell_argument(file_path)

      case RbConfig::CONFIG['host_os']
      when /mswin|mingw|cygwin/
        # Windows
        if application.include?('code')
          system("#{application} --goto #{quoted_path}:#{line_number}")
        else
          system("start \"\" \"#{file_path}\"")
        end
      when /darwin/
        # macOS
        if application == 'open'
          system("open #{quoted_path}")
        elsif application.include?('code')
          system("#{application} --goto #{quoted_path}:#{line_number}")
        elsif application.include?('vim') || application.include?('nvim')
          system("#{application} +#{line_number} #{quoted_path}")
        else
          system("#{application} #{quoted_path}")
        end
      else
        # Linux/Unix
        if application == 'open'
          system("xdg-open #{quoted_path}")
        elsif application.include?('code')
          system("#{application} --goto #{quoted_path}:#{line_number}")
        elsif application.include?('vim') || application.include?('nvim')
          system("#{application} +#{line_number} #{quoted_path}")
        else
          system("#{application} #{quoted_path}")
        end
      end
    rescue StandardError => e
      warn "ファイルを開けませんでした: #{e.message}"
      false
    end

    def quote_shell_argument(argument)
      if argument.include?(' ') || argument.include?("'") || argument.include?('"')
        '"' + argument.gsub('"', '\"') + '"'
      else
        argument
      end
    end
  end
end

