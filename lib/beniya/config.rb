# frozen_string_literal: true

module Beniya
  class Config
    # Default language settings
    DEFAULT_LANGUAGE = 'en'
    AVAILABLE_LANGUAGES = %w[en ja].freeze

    # Multi-language message definitions
    MESSAGES = {
      'en' => {
        # Application messages
        'app.interrupted' => 'beniya interrupted',
        'app.error_occurred' => 'Error occurred',
        'app.terminated' => 'beniya terminated',

        # File operations
        'file.not_found' => 'File not found',
        'file.not_readable' => 'File not readable',
        'file.read_error' => 'File read error',
        'file.binary_file' => 'Binary file',
        'file.cannot_preview' => 'Cannot preview',
        'file.encoding_error' => 'Character encoding error - cannot read file',
        'file.preview_error' => 'Preview error',
        'file.error_prefix' => 'Error',

        # Keybind messages
        'keybind.invalid_key' => 'invalid key',
        'keybind.search_text' => 'Search text: ',
        'keybind.no_matches' => 'No matches found.',
        'keybind.press_any_key' => 'Press any key to continue...',

        # UI messages
        'ui.operation_prompt' => 'Operation: ',

        # Help text
        'help.full' => 'j/k:move h:back l:enter o/Space:open g/G:top/bottom r:refresh q:quit',
        'help.short' => 'j/k:move h:back l:enter o:open q:quit',

        # Health check messages
        'health.title' => 'beniya Health Check',
        'health.ruby_version' => 'Ruby version',
        'health.required_gems' => 'Required gems',
        'health.fzf' => 'fzf (file search)',
        'health.rga' => 'rga (content search)',
        'health.file_opener' => 'System file opener',
        'health.summary' => 'Summary:',
        'health.ok' => 'OK',
        'health.warnings' => 'Warnings',
        'health.errors' => 'Errors',
        'health.all_passed' => 'All checks passed! beniya is ready to use.',
        'health.critical_missing' => 'Some critical components are missing. beniya may not work properly.',
        'health.optional_missing' => 'Some optional features are unavailable. Basic functionality will work.',
        'health.all_gems_installed' => 'All required gems installed',
        'health.missing_gems' => 'Missing gems',
        'health.gem_install_instruction' => 'Run: gem install',
        'health.tool_not_found' => 'not found',
        'health.unknown_platform' => 'Unknown platform',
        'health.file_open_may_not_work' => 'File opening may not work properly',
        'health.macos_opener' => 'macOS file opener',
        'health.linux_opener' => 'Linux file opener',
        'health.windows_opener' => 'Windows file opener',
        'health.install_brew' => 'Install: brew install',
        'health.install_apt' => 'Install: apt install',
        'health.install_guide' => 'Check installation guide for your platform',
        'health.rga_releases' => 'Install: https://github.com/phiresky/ripgrep-all/releases',
        'health.ruby_upgrade_needed' => 'Please upgrade Ruby to version 2.7.0 or higher'
      },

      'ja' => {
        # Application messages
        'app.interrupted' => 'beniyaを中断しました',
        'app.error_occurred' => 'エラーが発生しました',
        'app.terminated' => 'beniyaを終了しました',

        # File operations
        'file.not_found' => 'ファイルが見つかりません',
        'file.not_readable' => 'ファイルを読み取れません',
        'file.read_error' => 'ファイル読み込みエラー',
        'file.binary_file' => 'バイナリファイル',
        'file.cannot_preview' => 'プレビューできません',
        'file.encoding_error' => '文字エンコーディングエラー - ファイルを読み取れません',
        'file.preview_error' => 'プレビューエラー',
        'file.error_prefix' => 'エラー',

        # Keybind messages
        'keybind.invalid_key' => '無効なキー',
        'keybind.search_text' => '検索テキスト: ',
        'keybind.no_matches' => 'マッチするものが見つかりません。',
        'keybind.press_any_key' => '何かキーを押して続行...',

        # UI messages
        'ui.operation_prompt' => '操作: ',

        # Help text
        'help.full' => 'j/k:移動 h:戻る l:入る o/Space:開く g/G:先頭/末尾 r:更新 q:終了',
        'help.short' => 'j/k:移動 h:戻る l:入る o:開く q:終了',

        # Health check messages
        'health.title' => 'beniya ヘルスチェック',
        'health.ruby_version' => 'Ruby バージョン',
        'health.required_gems' => '必須 gem',
        'health.fzf' => 'fzf (ファイル検索)',
        'health.rga' => 'rga (内容検索)',
        'health.file_opener' => 'システムファイルオープナー',
        'health.summary' => 'サマリー:',
        'health.ok' => 'OK',
        'health.warnings' => '警告',
        'health.errors' => 'エラー',
        'health.all_passed' => '全てのチェックが完了しました！beniyaは使用可能です。',
        'health.critical_missing' => '重要なコンポーネントが不足しています。beniyaは正常に動作しない可能性があります。',
        'health.optional_missing' => 'オプション機能が利用できません。基本機能は動作します。',
        'health.all_gems_installed' => '全ての必須gemがインストールされています',
        'health.missing_gems' => '不足しているgem',
        'health.gem_install_instruction' => '実行: gem install',
        'health.tool_not_found' => 'が見つかりません',
        'health.unknown_platform' => '不明なプラットフォーム',
        'health.file_open_may_not_work' => 'ファイルオープンが正常に動作しない可能性があります',
        'health.macos_opener' => 'macOS ファイルオープナー',
        'health.linux_opener' => 'Linux ファイルオープナー',
        'health.windows_opener' => 'Windows ファイルオープナー',
        'health.install_brew' => 'インストール: brew install',
        'health.install_apt' => 'インストール: apt install',
        'health.install_guide' => 'お使いのプラットフォーム向けのインストールガイドを確認してください',
        'health.rga_releases' => 'インストール: https://github.com/phiresky/ripgrep-all/releases',
        'health.ruby_upgrade_needed' => 'Rubyをバージョン2.7.0以上にアップグレードしてください'
      }
    }.freeze

    class << self
      def current_language
        @current_language ||= detect_language
      end

      def current_language=(lang)
        if AVAILABLE_LANGUAGES.include?(lang.to_s)
          @current_language = lang.to_s
        else
          raise ArgumentError, "Unsupported language: #{lang}. Available: #{AVAILABLE_LANGUAGES.join(', ')}"
        end
      end

      def message(key, **interpolations)
        msg = MESSAGES.dig(current_language, key) || MESSAGES.dig(DEFAULT_LANGUAGE, key) || key
        
        # Simple interpolation support
        interpolations.each do |placeholder, value|
          msg = msg.gsub("%{#{placeholder}}", value.to_s)
        end
        
        msg
      end

      def available_languages
        AVAILABLE_LANGUAGES.dup
      end

      def reset_language!
        @current_language = nil
      end

      private

      def detect_language
        # Only BENIYA_LANG environment variable takes precedence
        # This ensures English is default unless explicitly requested
        env_lang = ENV['BENIYA_LANG']
        
        if env_lang && !env_lang.empty?
          # Extract language code (e.g., 'ja_JP.UTF-8' -> 'ja')
          lang_code = env_lang.split(/[_.]/).first&.downcase
          return lang_code if AVAILABLE_LANGUAGES.include?(lang_code)
        end
        
        DEFAULT_LANGUAGE
      end
    end
  end
end
