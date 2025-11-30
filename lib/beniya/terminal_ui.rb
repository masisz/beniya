# frozen_string_literal: true

require 'io/console'

module Beniya
  class TerminalUI
    # Layout constants
    HEADER_HEIGHT = 2              # Header占有行数
    FOOTER_HEIGHT = 1              # Footer占有行数
    HEADER_FOOTER_MARGIN = 4       # Header + Footer分のマージン

    # Panel layout ratios
    LEFT_PANEL_RATIO = 0.5         # 左パネルの幅比率
    RIGHT_PANEL_RATIO = 1.0 - LEFT_PANEL_RATIO

    # Display constants
    DEFAULT_SCREEN_WIDTH = 80      # デフォルト画面幅
    DEFAULT_SCREEN_HEIGHT = 24     # デフォルト画面高さ
    HEADER_PADDING = 2             # ヘッダーのパディング
    BASE_INFO_RESERVED_WIDTH = 20  # ベースディレクトリ表示の予約幅
    BASE_INFO_MIN_WIDTH = 10       # ベースディレクトリ表示の最小幅
    FILTER_TEXT_RESERVED = 15      # フィルタテキスト表示の予約幅

    # File display constants
    ICON_SIZE_PADDING = 12         # アイコン、選択マーク、サイズ情報分
    CURSOR_OFFSET = 1              # カーソル位置のオフセット

    # Size display constants (bytes)
    KILOBYTE = 1024
    MEGABYTE = KILOBYTE * 1024
    GIGABYTE = MEGABYTE * 1024

    # Line offsets
    CONTENT_START_LINE = 3         # コンテンツ開始行（ヘッダー2行スキップ）

    def initialize
      console = IO.console
      if console
        @screen_width, @screen_height = console.winsize.reverse
      else
        # fallback values (for test environments etc.)
        @screen_width = DEFAULT_SCREEN_WIDTH
        @screen_height = DEFAULT_SCREEN_HEIGHT
      end
      @running = false
      @command_mode_active = false
      @command_input = ""
      @command_mode = CommandMode.new
    end

    def start(directory_listing, keybind_handler, file_preview)
      @directory_listing = directory_listing
      @keybind_handler = keybind_handler
      @file_preview = file_preview
      @keybind_handler.set_directory_listing(@directory_listing)
      @keybind_handler.set_terminal_ui(self)

      @running = true
      setup_terminal

      begin
        main_loop
      ensure
        cleanup_terminal
      end
    end

    def refresh_display
      # ウィンドウサイズを更新してから画面をクリアして再描画
      update_screen_size
      print "\e[2J\e[H"  # clear screen, cursor to home
    end

    private

    def setup_terminal
      # terminal setup
      system('tput smcup')  # alternate screen
      system('tput civis')  # cursor invisible
      print "\e[2J\e[H"     # clear screen, cursor to home (first time only)

      # re-acquire terminal size (just in case)
      update_screen_size
    end

    def update_screen_size
      console = IO.console
      return unless console

      @screen_width, @screen_height = console.winsize.reverse
    end

    def cleanup_terminal
      system('tput rmcup')  # normal screen
      system('tput cnorm')  # cursor normal
      puts ConfigLoader.message('app.terminated')
    end

    def main_loop
      while @running
        draw_screen
        handle_input
      end
    end

    def draw_screen
      # move cursor to top of screen (don't clear)
      print "\e[H"

      # header (2 lines)
      draw_header
      draw_base_directory_info

      # main content (left: directory list, right: preview)
      entries = get_display_entries
      selected_entry = entries[@keybind_handler.current_index]

      # calculate height with header and footer margin
      content_height = @screen_height - HEADER_FOOTER_MARGIN
      left_width = (@screen_width * LEFT_PANEL_RATIO).to_i
      right_width = @screen_width - left_width

      # adjust so right panel doesn't overflow into left panel
      right_width = @screen_width - left_width if left_width + right_width > @screen_width

      draw_directory_list(entries, left_width, content_height)
      draw_file_preview(selected_entry, right_width, content_height, left_width)

      # footer
      draw_footer

      # コマンド実行結果を表示
      draw_command_result

      # コマンドモードがアクティブな場合はコマンド入力欄を表示
      if @command_mode_active
        draw_command_input
      else
        # move cursor to invisible position
        print "\e[#{@screen_height};#{@screen_width}H"
      end
    end

    def draw_header
      current_path = @directory_listing.current_path
      header = "📁 beniya - #{current_path}"

      # Add filter indicator if in filter mode
      if @keybind_handler.filter_active?
        filter_text = " [Filter: #{@keybind_handler.filter_query}]"
        header += filter_text
      end

      # abbreviate if path is too long
      if header.length > @screen_width - HEADER_PADDING
        if @keybind_handler.filter_active?
          # prioritize showing filter when active
          filter_text = " [Filter: #{@keybind_handler.filter_query}]"
          base_length = @screen_width - filter_text.length - FILTER_TEXT_RESERVED
          header = "📁 beniya - ...#{current_path[-base_length..-1]}#{filter_text}"
        else
          header = "📁 beniya - ...#{current_path[-(@screen_width - FILTER_TEXT_RESERVED)..-1]}"
        end
      end

      puts "\e[7m#{header.ljust(@screen_width)}\e[0m" # reverse display
    end

    def draw_base_directory_info
      # 強制的に表示 - デバッグ用に安全チェックを緩和
      if @keybind_handler && @keybind_handler.instance_variable_get(:@base_directory)
        base_dir = @keybind_handler.instance_variable_get(:@base_directory)
        selected_count = @keybind_handler.selected_items.length
        base_info = "📋 Base Directory: #{base_dir}"
        
        # 選択されたアイテム数を表示
        if selected_count > 0
          base_info += " | Selected: #{selected_count} item(s)"
        end
      else
        # keybind_handlerがない場合、またはbase_directoryが設定されていない場合
        base_info = "📋 Base Directory: #{Dir.pwd}"
      end
      
      # 長すぎる場合は省略
      if base_info.length > @screen_width - HEADER_PADDING
        if base_info.include?(" | Selected:")
          selected_part = base_info.split(" | Selected:").last
          available_length = @screen_width - BASE_INFO_RESERVED_WIDTH - " | Selected:#{selected_part}".length
        else
          available_length = @screen_width - BASE_INFO_RESERVED_WIDTH
        end
        
        if available_length > BASE_INFO_MIN_WIDTH
          # パスの最後の部分を表示
          dir_part = base_info.split(": ").last.split(" | ").first
          short_base_dir = "...#{dir_part[-available_length..-1]}"
          base_info = base_info.gsub(dir_part, short_base_dir)
        end
      end
      
      # 2行目に確実に表示
      print "\e[2;1H\e[44m\e[37m#{base_info.ljust(@screen_width)}\e[0m"
    end


    def draw_directory_list(entries, width, height)
      start_index = [@keybind_handler.current_index - height / 2, 0].max
      [start_index + height - 1, entries.length - 1].min

      (0...height).each do |i|
        entry_index = start_index + i
        line_num = i + CONTENT_START_LINE

        print "\e[#{line_num};1H" # set cursor position

        if entry_index < entries.length
          entry = entries[entry_index]
          is_selected = entry_index == @keybind_handler.current_index

          draw_entry_line(entry, width, is_selected)
        else
          # 左ペイン専用の安全な幅で空行を出力
          safe_width = [width - CURSOR_OFFSET, (@screen_width * LEFT_PANEL_RATIO).to_i - CURSOR_OFFSET].min
          print ' ' * safe_width
        end
      end
    end

    def draw_entry_line(entry, width, is_selected)
      # アイコンと色の設定
      icon, color = get_entry_display_info(entry)

      # 左ペイン専用の安全な幅を計算（右ペインにはみ出さないよう）
      safe_width = [width - CURSOR_OFFSET, (@screen_width * LEFT_PANEL_RATIO).to_i - CURSOR_OFFSET].min

      # 選択マークの追加
      selection_mark = @keybind_handler.is_selected?(entry[:name]) ? "✓ " : "  "

      # ファイル名（必要に応じて切り詰め）
      name = entry[:name]
      max_name_length = safe_width - ICON_SIZE_PADDING
      name = name[0...max_name_length - 3] + '...' if max_name_length > 0 && name.length > max_name_length

      # サイズ情報
      size_info = format_size(entry[:size])

      # 行の内容を構築（安全な幅内で）
      content_without_size = "#{selection_mark}#{icon} #{name}"
      available_for_content = safe_width - size_info.length

      line_content = if available_for_content > 0
                       content_without_size.ljust(available_for_content) + size_info
                     else
                       content_without_size
                     end

      # 確実に safe_width を超えないよう切り詰め
      line_content = line_content[0...safe_width]

      if is_selected
        selected_color = ColorHelper.color_to_selected_ansi(ConfigLoader.colors[:selected])
        print "#{selected_color}#{line_content}#{ColorHelper.reset}"
      else
        # 選択されたアイテムは異なる色で表示
        if @keybind_handler.is_selected?(entry[:name])
          print "\e[42m\e[30m#{line_content}\e[0m"  # 緑背景、黒文字
        else
          print "#{color}#{line_content}#{ColorHelper.reset}"
        end
      end
    end

    def get_entry_display_info(entry)
      colors = ConfigLoader.colors
      
      case entry[:type]
      when 'directory'
        color_code = ColorHelper.color_to_ansi(colors[:directory])
        ['📁', color_code]
      when 'executable'
        color_code = ColorHelper.color_to_ansi(colors[:executable])
        ['⚡', color_code]
      else
        case File.extname(entry[:name]).downcase
        when '.rb'
          ['💎', "\e[31m"]  # 赤
        when '.js', '.ts'
          ['📜', "\e[33m"]  # 黄
        when '.txt', '.md'
          color_code = ColorHelper.color_to_ansi(colors[:file])
          ['📄', color_code]
        else
          color_code = ColorHelper.color_to_ansi(colors[:file])
          ['📄', color_code]
        end
      end
    end

    def format_size(size)
      return '      ' if size == 0

      if size < KILOBYTE
        "#{size}B".rjust(6)
      elsif size < MEGABYTE
        "#{(size / KILOBYTE.to_f).round(1)}K".rjust(6)
      elsif size < GIGABYTE
        "#{(size / MEGABYTE.to_f).round(1)}M".rjust(6)
      else
        "#{(size / GIGABYTE.to_f).round(1)}G".rjust(6)
      end
    end

    def draw_file_preview(selected_entry, width, height, left_offset)
      (0...height).each do |i|
        line_num = i + CONTENT_START_LINE
        # カーソル位置を左パネルの右端に設定
        cursor_position = left_offset + CURSOR_OFFSET

        # 画面の境界を厳密に計算
        max_chars_from_cursor = @screen_width - cursor_position
        # 区切り線（│）分を除いて、さらに安全マージンを取る
        safe_width = [max_chars_from_cursor - 2, width - 2, 0].max

        print "\e[#{line_num};#{cursor_position}H" # カーソル位置設定
        print '│' # 区切り線

        content_to_print = ''

        if selected_entry && i == 0
          # プレビューヘッダー
          header = " #{selected_entry[:name]} "
          content_to_print = header
        elsif selected_entry && selected_entry[:type] == 'file' && i >= 2
          # ファイルプレビュー（折り返し対応）
          preview_content = get_preview_content(selected_entry)
          wrapped_lines = wrap_preview_lines(preview_content, safe_width - 1) # スペース分を除く
          display_line_index = i - 2

          if display_line_index < wrapped_lines.length
            line = wrapped_lines[display_line_index] || ''
            # スペースを先頭に追加
            content_to_print = " #{line}"
          else
            content_to_print = ' '
          end
        else
          content_to_print = ' '
        end

        # 絶対にsafe_widthを超えないよう強制的に切り詰める
        if safe_width <= 0
          # 表示スペースがない場合は何も出力しない
          next
        elsif display_width(content_to_print) > safe_width
          # 表示幅ベースで切り詰める
          content_to_print = truncate_to_width(content_to_print, safe_width)
        end

        # 出力（パディングなし、はみ出し防止のため）
        print content_to_print

        # 残りのスペースを埋める（ただし安全な範囲内のみ）
        remaining_space = safe_width - display_width(content_to_print)
        print ' ' * remaining_space if remaining_space > 0
      end
    end

    def get_preview_content(entry)
      return [] unless entry && entry[:type] == 'file'

      preview = @file_preview.preview_file(entry[:path])
      case preview[:type]
      when 'text', 'code'
        preview[:lines]
      when 'binary'
        ["(#{ConfigLoader.message('file.binary_file')})", ConfigLoader.message('file.cannot_preview')]
      when 'error'
        ["#{ConfigLoader.message('file.error_prefix')}:", preview[:message]]
      else
        ["(#{ConfigLoader.message('file.cannot_preview')})"]
      end
    rescue StandardError
      ["(#{ConfigLoader.message('file.preview_error')})"]
    end

    def wrap_preview_lines(lines, max_width)
      return [] if lines.empty? || max_width <= 0

      wrapped_lines = []

      lines.each do |line|
        if display_width(line) <= max_width
          # 短い行はそのまま追加
          wrapped_lines << line
        else
          # 長い行は折り返し
          remaining_line = line
          while display_width(remaining_line) > max_width
            # 単語境界で折り返すことを試みる
            break_point = find_break_point(remaining_line, max_width)
            wrapped_lines << remaining_line[0...break_point]
            remaining_line = remaining_line[break_point..-1]
          end
          # 残りの部分を追加
          wrapped_lines << remaining_line if remaining_line.length > 0
        end
      end

      wrapped_lines
    end

    def display_width(string)
      # 文字列の表示幅を計算する
      # 日本語文字（全角）は幅2、ASCII文字（半角）は幅1として計算
      width = 0
      string.each_char do |char|
        # 全角文字の判定
        width += if char.ord > 127 || char.match?(/[あ-ん ア-ン 一-龯]/)
                   2
                 else
                   1
                 end
      end
      width
    end

    def truncate_to_width(string, max_width)
      # 表示幅を指定して文字列を切り詰める
      return string if display_width(string) <= max_width

      current_width = 0
      result = ''

      string.each_char do |char|
        char_width = char.ord > 127 || char.match?(/[あ-ん ア-ン 一-龯]/) ? 2 : 1

        if current_width + char_width > max_width
          # "..."を追加できるかチェック
          result += '...' if max_width >= 3 && current_width <= max_width - 3
          break
        end

        result += char
        current_width += char_width
      end

      result
    end

    def find_break_point(line, max_width)
      # 最大幅以内で適切な折り返し位置を見つける
      return line.length if display_width(line) <= max_width

      # 文字ごとに幅を計算しながら適切な位置を探す
      current_width = 0
      best_break_point = 0
      space_break_point = nil
      punct_break_point = nil

      line.each_char.with_index do |char, index|
        char_width = char.ord > 127 || char.match?(/[あ-ん ア-ン 一-龯]/) ? 2 : 1

        break if current_width + char_width > max_width

        current_width += char_width
        best_break_point = index + 1

        # スペースで区切れる位置を記録
        space_break_point = index + 1 if char == ' ' && current_width > max_width * 0.5

        # 日本語の句読点で区切れる位置を記録
        punct_break_point = index + 1 if char.match?(/[、。，．！？]/) && current_width > max_width * 0.5
      end

      # 最適な折り返し位置を選択
      space_break_point || punct_break_point || best_break_point
    end

    def get_display_entries
      if @keybind_handler.filter_active?
        # Get filtered entries from keybind_handler
        all_entries = @directory_listing.list_entries
        query = @keybind_handler.filter_query.downcase
        query.empty? ? all_entries : all_entries.select { |entry| entry[:name].downcase.include?(query) }
      else
        @directory_listing.list_entries
      end
    end

    def draw_footer
      # 最下行から1行上に表示してスクロールを避ける
      footer_line = @screen_height - FOOTER_HEIGHT
      print "\e[#{footer_line};1H"

      if @keybind_handler.filter_active?
        if @keybind_handler.instance_variable_get(:@filter_mode)
          help_text = "Filter mode: Type to filter, ESC to clear, Enter to apply, Backspace to delete"
        else
          help_text = "Filtered view active - Space to edit filter, ESC to clear filter"
        end
      else
        help_text = ConfigLoader.message('help.full')
        help_text = ConfigLoader.message('help.short') if help_text.length > @screen_width
      end

      # 文字列を確実に画面幅に合わせる
      footer_content = help_text.ljust(@screen_width)[0...@screen_width]
      print "\e[7m#{footer_content}\e[0m"
    end

    def handle_input
      begin
        input = STDIN.getch
      rescue Errno::ENOTTY, Errno::ENODEV
        # ターミナルでない環境（IDE等）では標準入力を使用
        print "\nOperation: "
        input = STDIN.gets
        return 'q' if input.nil?
        input = input.chomp.downcase
        return input[0] if input.length > 0

        return 'q'
      end

      # 特殊キーの処理
      if input == "\e"
        # エスケープシーケンスの処理
        next_char = begin
          STDIN.read_nonblock(1)
        rescue StandardError
          nil
        end
        if next_char == '['
          arrow_key = begin
            STDIN.read_nonblock(1)
          rescue StandardError
            nil
          end
          input = case arrow_key
                  when 'A'  # 上矢印
                    'k'
                  when 'B'  # 下矢印
                    'j'
                  when 'C'  # 右矢印
                    'l'
                  when 'D'  # 左矢印
                    'h'
                  else
                    "\e" # ESCキー（そのまま保持）
                  end
        else
          input = "\e" # ESCキー（そのまま保持）
        end
      end

      # コマンドモードがアクティブな場合は、コマンド入力を処理
      if @command_mode_active
        handle_command_input(input)
        return
      end

      # キーバインドハンドラーに処理を委譲
      result = @keybind_handler.handle_key(input)

      # 終了処理（qキーのみ）
      if input == 'q'
        @running = false
      end
    end

    # コマンドモード関連のメソッドは public にする
    public

    # コマンドモードを起動
    def activate_command_mode
      @command_mode_active = true
      @command_input = ""
    end

    # コマンドモードを終了
    def deactivate_command_mode
      @command_mode_active = false
      @command_input = ""
    end

    # コマンドモードがアクティブかどうか
    def command_mode_active?
      @command_mode_active
    end

    # コマンド入力を処理
    def handle_command_input(input)
      case input
      when "\r", "\n"
        # Enter キーでコマンドを実行
        execute_command(@command_input)
        deactivate_command_mode
      when "\e"
        # Escape キーでコマンドモードをキャンセル
        deactivate_command_mode
      when "\u007F", "\b"
        # Backspace
        @command_input.chop! unless @command_input.empty?
      else
        # 通常の文字を追加
        @command_input += input if input.length == 1
      end
    end

    # コマンドを実行
    def execute_command(command_string)
      return if command_string.nil? || command_string.empty?

      result = @command_mode.execute(command_string)

      # コマンド実行結果を表示（画面下部に一時的に表示）
      if result
        @command_result = result
        @command_result_time = Time.now
      end
    end

    # コマンド入力欄を描画
    def draw_command_input
      # 画面最下部に描画
      print "\e[#{@screen_height};1H"
      print "\e[2K"  # 行をクリア

      # コマンドプロンプトと入力を表示
      prompt = ":"
      print "#{prompt}#{@command_input}"

      # カーソルを表示
      print "\e[?25h"
    end

    # コマンド実行結果を描画
    def draw_command_result
      return unless @command_result && @command_result_time

      # 3秒間だけ表示
      if Time.now - @command_result_time < 3
        print "\e[#{@screen_height - 1};1H"
        print "\e[2K"  # 行をクリア
        print @command_result
      else
        @command_result = nil
        @command_result_time = nil
      end
    end
  end
end

