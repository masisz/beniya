# frozen_string_literal: true

require 'fileutils'

module Beniya
  # Manages the deprecation notice for the transition from beniya to rufio
  class DeprecationNotice
    NOTICE_FILE = File.join(Dir.home, '.beniya', '.deprecation_notice_shown')

    def initialize
      ensure_config_directory
    end

    # Check if the notice should be shown
    # @return [Boolean] true if the notice should be shown
    def should_show?
      !File.exist?(NOTICE_FILE)
    end

    # Mark the notice as shown
    def mark_as_shown
      FileUtils.touch(NOTICE_FILE)
    end

    # Get the notice title
    # @return [String] The notice title
    def title
      ConfigLoader.message('deprecation.title')
    rescue StandardError
      '重要なお知らせ / Important Notice'
    end

    # Get the notice content lines
    # @return [Array<String>] The notice content lines
    def content
      if ConfigLoader.language == 'ja'
        japanese_content
      else
        english_content
      end
    rescue StandardError
      # Fallback content if ConfigLoader fails
      fallback_content
    end

    private

    def ensure_config_directory
      config_dir = File.join(Dir.home, '.beniya')
      FileUtils.mkdir_p(config_dir) unless Dir.exist?(config_dir)
    end

    def japanese_content
      [
        '',
        'beniyaはrufioに改名されました。',
        '',
        '今後の開発とサポートはrufioで継続されます。',
        'beniyaは非推奨となり、将来的に削除される予定です。',
        '',
        '移行方法:',
        '  1. gem uninstall beniya',
        '  2. gem install rufio',
        '',
        '詳細: https://github.com/masisz/rufio',
        '',
        '任意のキーを押して続行...',
        ''
      ]
    end

    def english_content
      [
        '',
        'beniya has been renamed to rufio.',
        '',
        'Future development and support will continue as rufio.',
        'beniya is now deprecated and will be removed in the future.',
        '',
        'Migration steps:',
        '  1. gem uninstall beniya',
        '  2. gem install rufio',
        '',
        'More info: https://github.com/masisz/rufio',
        '',
        'Press any key to continue...',
        ''
      ]
    end

    def fallback_content
      [
        '',
        'beniya has been renamed to rufio.',
        'beniyaはrufioに改名されました。',
        '',
        'Please install rufio instead:',
        '  gem install rufio',
        '',
        'Press any key to continue...',
        ''
      ]
    end
  end
end
