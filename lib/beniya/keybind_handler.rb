# frozen_string_literal: true

require_relative 'bookmark'

module Beniya
  class KeybindHandler
    attr_reader :current_index, :filter_query

    def initialize
      @current_index = 0
      @directory_listing = nil
      @terminal_ui = nil
      @file_opener = FileOpener.new
      @filter_mode = false
      @filter_query = ''
      @filtered_entries = []
      @original_entries = []
      @selected_items = []
      @base_directory = nil
      @bookmark = Bookmark.new
    end

    def set_directory_listing(directory_listing)
      @directory_listing = directory_listing
      @current_index = 0
    end

    def set_terminal_ui(terminal_ui)
      @terminal_ui = terminal_ui
    end

    def set_base_directory(base_dir)
      @base_directory = File.expand_path(base_dir)
    end

    def selected_items
      @selected_items.dup
    end

    def is_selected?(entry_name)
      @selected_items.include?(entry_name)
    end

    def handle_key(key)
      return false unless @directory_listing

      # フィルターモード中は他のキーバインドを無効化
      return handle_filter_input(key) if @filter_mode

      case key
      when 'j'
        move_down
      when 'k'
        move_up
      when 'h'
        navigate_parent
      when 'l', "\r", "\n" # l, Enter
        navigate_enter
      when 'g'
        move_to_top
      when 'G'
        move_to_bottom
      when 'r'
        refresh
      when 'o'  # o
        open_current_file
      when 'e'  # e - open directory in file explorer
        open_directory_in_explorer
      when 's'  # s - filter files
        if !@filter_query.empty?
          # フィルタが設定されている場合は再編集モードに入る
          @filter_mode = true
          @original_entries = @directory_listing.list_entries.dup if @original_entries.empty?
        else
          # 新規フィルターモード開始
          start_filter_mode
        end
      when ' ' # Space - toggle selection
        toggle_selection
      when "\e" # ESC
        if !@filter_query.empty?
          # フィルタが設定されている場合はクリア
          clear_filter_mode
          true
        else
          false
        end
      when 'q'  # q
        exit_request
      when '/'  # /
        fzf_search
      when 'f'  # f - file name search with fzf
        fzf_search
      when 'F'  # F - file content search with rga
        rga_search
      when 'a'  # a
        create_file
      when 'A'  # A
        create_directory
      when 'm'  # m - move selected files to base directory
        move_selected_to_base
      when 'p'  # p - copy selected files to base directory
        copy_selected_to_base
      when 'x'  # x - delete selected files
        delete_selected_files
      when 'b'  # b - bookmark operations
        show_bookmark_menu
      when '1', '2', '3', '4', '5', '6', '7', '8', '9'  # number keys - go to bookmark
        goto_bookmark(key.to_i)
      else
        false # #{ConfigLoader.message('keybind.invalid_key')}
      end
    end

    def select_index(index)
      entries = get_active_entries
      @current_index = [[index, 0].max, entries.length - 1].min
    end

    def current_entry
      entries = get_active_entries
      entries[@current_index]
    end

    def filter_active?
      @filter_mode || !@filter_query.empty?
    end

    def get_active_entries
      if @filter_mode || !@filter_query.empty?
        @filtered_entries.empty? ? [] : @filtered_entries
      else
        @directory_listing&.list_entries || []
      end
    end

    private

    def move_down
      entries = get_active_entries
      @current_index = [@current_index + 1, entries.length - 1].min
      true
    end

    def move_up
      @current_index = [@current_index - 1, 0].max
      true
    end

    def move_to_top
      @current_index = 0
      true
    end

    def move_to_bottom
      entries = get_active_entries
      @current_index = entries.length - 1
      true
    end

    def navigate_enter
      entry = current_entry
      return false unless entry

      if entry[:type] == 'directory'
        result = @directory_listing.navigate_to(entry[:name])
        if result
          @current_index = 0  # select first entry in new directory
          clear_filter_mode   # ディレクトリ移動時にフィルタをリセット
        end
        result
      else
        # do nothing for files (file opening feature may be added in the future)
        false
      end
    end

    def navigate_parent
      result = @directory_listing.navigate_to_parent
      if result
        @current_index = 0  # select first entry in parent directory
        clear_filter_mode   # ディレクトリ移動時にフィルタをリセット
      end
      result
    end

    def refresh
      # ウィンドウサイズを更新して画面を再描画
      @terminal_ui&.refresh_display

      @directory_listing.refresh
      if @filter_mode || !@filter_query.empty?
        # Re-apply filter with new directory contents
        @original_entries = @directory_listing.list_entries.dup
        apply_filter
      else
        # adjust index to stay within bounds after refresh
        entries = @directory_listing.list_entries
        @current_index = [@current_index, entries.length - 1].min if entries.any?
      end
      true
    end

    def open_current_file
      entry = current_entry
      return false unless entry

      if entry[:type] == 'file'
        @file_opener.open_file(entry[:path])
        true
      else
        false
      end
    end

    def open_directory_in_explorer
      current_path = @directory_listing&.current_path || Dir.pwd
      @file_opener.open_directory_in_explorer(current_path)
      true
    end

    def exit_request
      true # request exit
    end

    def fzf_search
      return false unless fzf_available?

      current_path = @directory_listing&.current_path || Dir.pwd

      # fzfでファイル検索を実行
      selected_file = `cd "#{current_path}" && find . -type f | fzf --preview 'cat {}'`.strip

      # ファイルが選択された場合、そのファイルを開く
      if !selected_file.empty? && File.exist?(File.join(current_path, selected_file))
        full_path = File.expand_path(selected_file, current_path)
        @file_opener.open_file(full_path)
      end

      true
    end

    def fzf_available?
      system('which fzf > /dev/null 2>&1')
    end

    def rga_search
      return false unless rga_available?

      current_path = @directory_listing&.current_path || Dir.pwd

      # input search keyword
      print ConfigLoader.message('keybind.search_text')
      search_query = STDIN.gets.chomp
      return false if search_query.empty?

      # execute rga file content search
      search_results = `cd "#{current_path}" && rga --line-number --with-filename "#{search_query}" . 2>/dev/null`

      if search_results.empty?
        puts "\n#{ConfigLoader.message('keybind.no_matches')}"
        print ConfigLoader.message('keybind.press_any_key')
        STDIN.getch
        return true
      end

      # pass results to fzf for selection
      selected_result = IO.popen('fzf', 'r+') do |fzf|
        fzf.write(search_results)
        fzf.close_write
        fzf.read.strip
      end

      # extract file path and line number from selected result
      if !selected_result.empty? && selected_result.match(/^(.+?):(\d+):/)
        file_path = ::Regexp.last_match(1)
        line_number = ::Regexp.last_match(2).to_i
        full_path = File.expand_path(file_path, current_path)

        @file_opener.open_file_with_line(full_path, line_number) if File.exist?(full_path)
      end

      true
    end

    def rga_available?
      system('which rga > /dev/null 2>&1')
    end

    def start_filter_mode
      @filter_mode = true
      @filter_query = ''
      @original_entries = @directory_listing.list_entries.dup
      @filtered_entries = @original_entries.dup
      @current_index = 0
      true
    end

    def handle_filter_input(key)
      case key
      when "\e" # ESC - フィルタをクリアして通常モードに戻る
        clear_filter_mode
      when "\r", "\n" # Enter - フィルタを維持して通常モードに戻る
        exit_filter_mode_keep_filter
      when "\u007f", "\b" # Backspace
        if @filter_query.length > 0
          @filter_query = @filter_query[0...-1]
          apply_filter
        else
          clear_filter_mode
        end
      else
        # printable characters (英数字、記号、日本語文字など)
        if key.length == 1 && key.ord >= 32 && key.ord < 127 # ASCII printable
          @filter_query += key
          apply_filter
        elsif key.bytesize > 1 # Multi-byte characters (Japanese, etc.)
          @filter_query += key
          apply_filter
        end
        # その他のキー（Ctrl+c等）は無視
      end
      true
    end

    def apply_filter
      if @filter_query.empty?
        @filtered_entries = @original_entries.dup
      else
        query_downcase = @filter_query.downcase
        @filtered_entries = @original_entries.select do |entry|
          entry[:name].downcase.include?(query_downcase)
        end
      end
      @current_index = [@current_index, [@filtered_entries.length - 1, 0].max].min
    end

    def exit_filter_mode_keep_filter
      # フィルタを維持したまま通常モードに戻る
      @filter_mode = false
      # @filter_query, @filtered_entries は維持
    end

    def clear_filter_mode
      # フィルタをクリアして通常モードに戻る
      @filter_mode = false
      @filter_query = ''
      @filtered_entries = []
      @original_entries = []
      @current_index = 0
    end

    def exit_filter_mode
      # 既存メソッド（後方互換用）
      clear_filter_mode
    end

    def create_file
      current_path = @directory_listing&.current_path || Dir.pwd

      # ファイル名の入力を求める
      print ConfigLoader.message('keybind.input_filename')
      filename = STDIN.gets.chomp
      return false if filename.empty?

      # 不正なファイル名のチェック
      if filename.include?('/') || filename.include?('\\')
        puts "\n#{ConfigLoader.message('keybind.invalid_filename')}"
        print ConfigLoader.message('keybind.press_any_key')
        STDIN.getch
        return false
      end

      file_path = File.join(current_path, filename)

      # ファイルが既に存在する場合の確認
      if File.exist?(file_path)
        puts "\n#{ConfigLoader.message('keybind.file_exists')}"
        print ConfigLoader.message('keybind.press_any_key')
        STDIN.getch
        return false
      end

      begin
        # ファイルを作成
        File.write(file_path, '')

        # ディレクトリ表示を更新
        @directory_listing.refresh

        # 作成したファイルを選択状態にする
        entries = @directory_listing.list_entries
        new_file_index = entries.find_index { |entry| entry[:name] == filename }
        @current_index = new_file_index if new_file_index

        puts "\n#{ConfigLoader.message('keybind.file_created')}: #{filename}"
        print ConfigLoader.message('keybind.press_any_key')
        STDIN.getch
        true
      rescue StandardError => e
        puts "\n#{ConfigLoader.message('keybind.creation_error')}: #{e.message}"
        print ConfigLoader.message('keybind.press_any_key')
        STDIN.getch
        false
      end
    end

    def create_directory
      current_path = @directory_listing&.current_path || Dir.pwd

      # ディレクトリ名の入力を求める
      print ConfigLoader.message('keybind.input_dirname')
      dirname = STDIN.gets.chomp
      return false if dirname.empty?

      # 不正なディレクトリ名のチェック
      if dirname.include?('/') || dirname.include?('\\')
        puts "\n#{ConfigLoader.message('keybind.invalid_dirname')}"
        print ConfigLoader.message('keybind.press_any_key')
        STDIN.getch
        return false
      end

      dir_path = File.join(current_path, dirname)

      # ディレクトリが既に存在する場合の確認
      if File.exist?(dir_path)
        puts "\n#{ConfigLoader.message('keybind.directory_exists')}"
        print ConfigLoader.message('keybind.press_any_key')
        STDIN.getch
        return false
      end

      begin
        # ディレクトリを作成
        Dir.mkdir(dir_path)

        # ディレクトリ表示を更新
        @directory_listing.refresh

        # 作成したディレクトリを選択状態にする
        entries = @directory_listing.list_entries
        new_dir_index = entries.find_index { |entry| entry[:name] == dirname }
        @current_index = new_dir_index if new_dir_index

        puts "\n#{ConfigLoader.message('keybind.directory_created')}: #{dirname}"
        print ConfigLoader.message('keybind.press_any_key')
        STDIN.getch
        true
      rescue StandardError => e
        puts "\n#{ConfigLoader.message('keybind.creation_error')}: #{e.message}"
        print ConfigLoader.message('keybind.press_any_key')
        STDIN.getch
        false
      end
    end

    def toggle_selection
      entry = current_entry
      return false unless entry

      if @selected_items.include?(entry[:name])
        @selected_items.delete(entry[:name])
      else
        @selected_items << entry[:name]
      end
      true
    end

    def move_selected_to_base
      return false if @selected_items.empty? || @base_directory.nil?

      if show_confirmation_dialog('Move', @selected_items.length)
        perform_file_operation(:move, @selected_items, @base_directory)
      else
        false
      end
    end

    def copy_selected_to_base
      return false if @selected_items.empty? || @base_directory.nil?

      if show_confirmation_dialog('Copy', @selected_items.length)
        perform_file_operation(:copy, @selected_items, @base_directory)
      else
        false
      end
    end

    def show_confirmation_dialog(operation, count)
      print "\n#{operation} #{count} item(s)? (y/n): "
      response = STDIN.gets.chomp.downcase
      %w[y yes].include?(response)
    end

    def perform_file_operation(operation, items, destination)
      success_count = 0
      current_path = @directory_listing&.current_path || Dir.pwd

      items.each do |item_name|
        source_path = File.join(current_path, item_name)
        dest_path = File.join(destination, item_name)

        begin
          case operation
          when :move
            if File.exist?(dest_path)
              puts "\n#{item_name} already exists in destination. Skipping."
              next
            end
            FileUtils.mv(source_path, dest_path)
          when :copy
            if File.exist?(dest_path)
              puts "\n#{item_name} already exists in destination. Skipping."
              next
            end
            if File.directory?(source_path)
              FileUtils.cp_r(source_path, dest_path)
            else
              FileUtils.cp(source_path, dest_path)
            end
          end
          success_count += 1
        rescue StandardError => e
          puts "\nFailed to #{operation == :move ? 'move' : 'copy'} #{item_name}: #{e.message}"
        end
      end

      # 操作完了後の処理
      @selected_items.clear
      @directory_listing.refresh if @directory_listing

      puts "\n#{operation == :move ? 'Moved' : 'Copied'} #{success_count} item(s)."
      print 'Press any key to continue...'
      STDIN.getch
      true
    end

    def delete_selected_files
      return false if @selected_items.empty?

      if show_delete_confirmation(@selected_items.length)
        perform_delete_operation(@selected_items)
      else
        false
      end
    end

    def show_delete_confirmation(count)
      show_floating_delete_confirmation(count)
    end

    def show_floating_delete_confirmation(count)
      # コンテンツの準備
      title = 'Delete Confirmation'
      content_lines = [
        '',
        "Delete #{count} item(s)?",
        '',
        '  [Y]es - Delete',
        '  [N]o  - Cancel',
        ''
      ]

      # ダイアログのサイズ設定（コンテンツに合わせて調整）
      dialog_width = 45
      # タイトルあり: 上枠1 + タイトル1 + 区切り1 + コンテンツ6 + 下枠1 = 10
      dialog_height = 4 + content_lines.length

      # ダイアログの位置を中央に設定
      x, y = get_screen_center(dialog_width, dialog_height)

      # ダイアログの描画
      draw_floating_window(x, y, dialog_width, dialog_height, title, content_lines, {
                             border_color: "\e[31m", # 赤色（警告）
                             title_color: "\e[1;31m",   # 太字赤色
                             content_color: "\e[37m"    # 白色
                           })

      # フラッシュしてユーザーの注意を引く
      print "\a" # ベル音

      # キー入力待機
      loop do
        input = STDIN.getch.downcase

        case input
        when 'y'
          # ダイアログをクリア
          clear_floating_window_area(x, y, dialog_width, dialog_height)
          @terminal_ui&.refresh_display # 画面を再描画
          return true
        when 'n', "\e", "\x03" # n, ESC, Ctrl+C
          # ダイアログをクリア
          clear_floating_window_area(x, y, dialog_width, dialog_height)
          @terminal_ui&.refresh_display # 画面を再描画
          return false
        when 'q' # qキーでもキャンセル
          clear_floating_window_area(x, y, dialog_width, dialog_height)
          @terminal_ui&.refresh_display
          return false
        end
        # 無効なキー入力の場合は再度ループ
      end
    end

    def perform_delete_operation(items)
      success_count = 0
      error_messages = []
      current_path = @directory_listing&.current_path || Dir.pwd
      debug_log = []

      items.each do |item_name|
        item_path = File.join(current_path, item_name)
        debug_log << "Processing: #{item_name}"

        begin
          # ファイル/ディレクトリの存在確認
          unless File.exist?(item_path)
            error_messages << "#{item_name}: File not found"
            debug_log << '  Error: File not found'
            next
          end

          debug_log << '  Existence check: OK'
          is_directory = File.directory?(item_path)
          debug_log << "  Type: #{is_directory ? 'Directory' : 'File'}"

          if is_directory
            FileUtils.rm_rf(item_path)
            debug_log << '  FileUtils.rm_rf executed'
          else
            FileUtils.rm(item_path)
            debug_log << '  FileUtils.rm executed'
          end

          # 削除が実際に成功したかを確認
          sleep(0.01) # 10ms待機してファイルシステムの同期を待つ
          still_exists = File.exist?(item_path)
          debug_log << "  Post-deletion check: #{still_exists}"

          if still_exists
            error_messages << "#{item_name}: Deletion failed"
            debug_log << '  Result: Failed'
          else
            success_count += 1
            debug_log << '  Result: Success'
          end
        rescue StandardError => e
          error_messages << "#{item_name}: #{e.message}"
          debug_log << "  Exception: #{e.message}"
        end
      end

      # デバッグログをファイルに出力（開発時のみ）
      if ENV['BENIYA_DEBUG'] == '1'
        debug_file = File.join(Dir.home, '.beniya_delete_debug.log')
        File.open(debug_file, 'a') do |f|
          f.puts "=== Delete Process Debug #{Time.now} ==="
          f.puts "Target directory: #{current_path}"
          f.puts "Target items: #{items.inspect}"
          debug_log.each { |line| f.puts line }
          f.puts "Final result: #{success_count} successful, #{items.length - success_count} failed"
          f.puts "Error messages: #{error_messages.inspect}"
          f.puts ''
        end
      end


      # デバッグ用：削除結果の値をログファイルに出力
      result_debug_file = File.join(Dir.home, '.beniya_result_debug.log')
      File.open(result_debug_file, 'a') do |f|
        f.puts "=== Delete Result Debug #{Time.now} ==="
        f.puts "success_count: #{success_count}"
        f.puts "total_count: #{items.length}"
        f.puts "error_messages.length: #{error_messages.length}"
        f.puts "has_errors: #{!error_messages.empty?}"
        f.puts "condition check: success_count == total_count && !has_errors = #{success_count == items.length && error_messages.empty?}"
        f.puts ""
      end

      # 削除結果をフローティングウィンドウで表示
      show_deletion_result(success_count, items.length, error_messages)

      # 削除完了後の処理
      @selected_items.clear
      @directory_listing.refresh if @directory_listing

      true
    end

    def show_deletion_result(success_count, total_count, error_messages = [])
      # 詳細デバッグログを出力
      detailed_debug_file = File.join(Dir.home, '.beniya_detailed_debug.log')
      File.open(detailed_debug_file, 'a') do |f|
        f.puts "=== show_deletion_result called #{Time.now} ==="
        f.puts "Arguments: success_count=#{success_count}, total_count=#{total_count}"
        f.puts "error_messages: #{error_messages.inspect}"
        f.puts "error_messages.empty?: #{error_messages.empty?}"
        f.puts ""
      end

      # エラーメッセージがある場合はダイアログサイズを拡大
      has_errors = !error_messages.empty?
      dialog_width = has_errors ? 50 : 35
      dialog_height = has_errors ? [8 + error_messages.length, 15].min : 6

      # ダイアログの位置を中央に設定
      x, y = get_screen_center(dialog_width, dialog_height)

      # 成功・失敗に応じた色設定
      # デバッグ: success_count == total_count かつ has_errors が false の場合のみ成功扱い
      if success_count == total_count && !has_errors
        border_color = "\e[32m"   # 緑色（成功）
        title_color = "\e[1;32m"  # 太字緑色
        title = 'Delete Complete'
        message = "Deleted #{success_count} item(s)"
      else
        border_color = "\e[33m"   # 黄色（警告）
        title_color = "\e[1;33m"  # 太字黄色
        title = 'Delete Result'
        if success_count == total_count && has_errors
          # 全て削除成功したがエラーメッセージがある場合（本来ここに入らないはず）
          message = "#{success_count} deleted (with error info)"
        else
          failed_count = total_count - success_count
          message = "#{success_count} deleted, #{failed_count} failed"
        end
      end

      # コンテンツの準備
      content_lines = ['', message]

      # デバッグ情報を追加（開発中のみ）
      content_lines << ""
      content_lines << "DEBUG: success=#{success_count}, total=#{total_count}, errors=#{error_messages.length}"

      # エラーメッセージがある場合は追加
      if has_errors
        content_lines << ''
        content_lines << 'Error details:'
        error_messages.each { |error| content_lines << "  #{error}" }
      end

      content_lines << ''
      content_lines << 'Press any key to continue...'

      # ダイアログの描画
      draw_floating_window(x, y, dialog_width, dialog_height, title, content_lines, {
                             border_color: border_color,
                             title_color: title_color,
                             content_color: "\e[37m"
                           })

      # キー入力待機
      STDIN.getch

      # ダイアログをクリア
      clear_floating_window_area(x, y, dialog_width, dialog_height)
      @terminal_ui&.refresh_display
    end

    # フローティングウィンドウの基盤メソッド
    def draw_floating_window(x, y, width, height, title, content_lines, options = {})
      # デフォルトオプション
      border_color = options[:border_color] || "\e[37m"  # 白色
      title_color = options[:title_color] || "\e[1;33m"  # 黄色（太字）
      content_color = options[:content_color] || "\e[37m" # 白色
      reset_color = "\e[0m"

      # ウィンドウの描画
      # 上辺
      print "\e[#{y};#{x}H#{border_color}┌#{'─' * (width - 2)}┐#{reset_color}"

      # タイトル行
      if title
        title_width = display_width(title)
        title_padding = (width - 2 - title_width) / 2
        padded_title = ' ' * title_padding + title
        title_line = pad_string_to_width(padded_title, width - 2)
        print "\e[#{y + 1};#{x}H#{border_color}│#{title_color}#{title_line}#{border_color}│#{reset_color}"

        # タイトル区切り線
        print "\e[#{y + 2};#{x}H#{border_color}├#{'─' * (width - 2)}┤#{reset_color}"
        content_start_y = y + 3
      else
        content_start_y = y + 1
      end

      # コンテンツ行
      content_height = title ? height - 4 : height - 2
      content_lines.each_with_index do |line, index|
        break if index >= content_height

        line_y = content_start_y + index
        line_content = pad_string_to_width(line, width - 2) # 正確な幅でパディング
        print "\e[#{line_y};#{x}H#{border_color}│#{content_color}#{line_content}#{border_color}│#{reset_color}"
      end

      # 空行を埋める
      remaining_lines = content_height - content_lines.length
      remaining_lines.times do |i|
        line_y = content_start_y + content_lines.length + i
        empty_line = ' ' * (width - 2)
        print "\e[#{line_y};#{x}H#{border_color}│#{empty_line}│#{reset_color}"
      end

      # 下辺
      bottom_y = y + height - 1
      print "\e[#{bottom_y};#{x}H#{border_color}└#{'─' * (width - 2)}┘#{reset_color}"
    end

    def display_width(str)
      # 日本語文字の幅を考慮した文字列幅の計算
      # Unicode East Asian Width プロパティを考慮
      str.each_char.map do |char|
        case char
        when /[\u3000-\u303F\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF\uFF00-\uFFEF]/
          # 日本語の文字（ひらがな、カタカナ、漢字、全角記号）
          2
        when /[\u0020-\u007E]/
          # ASCII文字
          1
        else
          # その他の文字はバイト数で判断
          char.bytesize > 1 ? 2 : 1
        end
      end.sum
    end

    def pad_string_to_width(str, target_width)
      # 文字列を指定した表示幅になるようにパディング
      current_width = display_width(str)
      if current_width >= target_width
        # 文字列が長すぎる場合は切り詰め
        truncate_to_width(str, target_width)
      else
        # 不足分をスペースで埋める
        str + ' ' * (target_width - current_width)
      end
    end

    def truncate_to_width(str, max_width)
      # 指定した表示幅に収まるように文字列を切り詰め
      result = ''
      current_width = 0

      str.each_char do |char|
        char_width = display_width(char)
        break if current_width + char_width > max_width

        result += char
        current_width += char_width
      end

      result
    end

    def get_screen_center(content_width, content_height)
      # ターミナルのサイズを取得
      console = IO.console
      if console
        screen_width, screen_height = console.winsize.reverse
      else
        screen_width = 80
        screen_height = 24
      end

      # 中央位置を計算
      x = [(screen_width - content_width) / 2, 1].max
      y = [(screen_height - content_height) / 2, 1].max

      [x, y]
    end

    def clear_floating_window_area(x, y, width, height)
      # フローティングウィンドウの領域をクリア
      height.times do |row|
        print "\e[#{y + row};#{x}H#{' ' * width}"
      end
    end

    # ブックマーク機能
    def show_bookmark_menu
      current_path = @directory_listing&.current_path || Dir.pwd
      
      # メニューの準備
      title = 'Bookmark Menu'
      content_lines = [
        '',
        '[A]dd current directory to bookmarks',
        '[L]ist bookmarks',
        '[R]emove bookmark',
        '',
        'Press 1-9 to go to bookmark directly',
        '',
        'Press any other key to cancel'
      ]

      dialog_width = 45
      dialog_height = 4 + content_lines.length
      x, y = get_screen_center(dialog_width, dialog_height)

      # ダイアログの描画
      draw_floating_window(x, y, dialog_width, dialog_height, title, content_lines, {
                             border_color: "\e[34m", # 青色
                             title_color: "\e[1;34m",   # 太字青色
                             content_color: "\e[37m"    # 白色
                           })

      # キー入力待機
      loop do
        input = STDIN.getch.downcase

        case input
        when 'a'
          clear_floating_window_area(x, y, dialog_width, dialog_height)
          @terminal_ui&.refresh_display
          add_bookmark_interactive(current_path)
          return true
        when 'l'
          clear_floating_window_area(x, y, dialog_width, dialog_height)
          @terminal_ui&.refresh_display
          list_bookmarks_interactive
          return true
        when 'r'
          clear_floating_window_area(x, y, dialog_width, dialog_height)
          @terminal_ui&.refresh_display
          remove_bookmark_interactive
          return true
        when '1', '2', '3', '4', '5', '6', '7', '8', '9'
          clear_floating_window_area(x, y, dialog_width, dialog_height)
          @terminal_ui&.refresh_display
          goto_bookmark(input.to_i)
          return true
        else
          # キャンセル
          clear_floating_window_area(x, y, dialog_width, dialog_height)
          @terminal_ui&.refresh_display
          return false
        end
      end
    end

    def add_bookmark_interactive(path)
      print ConfigLoader.message('bookmark.input_name') || "Enter bookmark name: "
      name = STDIN.gets.chomp
      return false if name.empty?

      if @bookmark.add(path, name)
        puts "\n#{ConfigLoader.message('bookmark.added') || 'Bookmark added'}: #{name}"
      else
        puts "\n#{ConfigLoader.message('bookmark.add_failed') || 'Failed to add bookmark'}"
      end
      
      print ConfigLoader.message('keybind.press_any_key') || 'Press any key to continue...'
      STDIN.getch
      true
    end

    def remove_bookmark_interactive
      bookmarks = @bookmark.list
      
      if bookmarks.empty?
        puts "\n#{ConfigLoader.message('bookmark.no_bookmarks') || 'No bookmarks found'}"
        print ConfigLoader.message('keybind.press_any_key') || 'Press any key to continue...'
        STDIN.getch
        return false
      end

      puts "\nBookmarks:"
      bookmarks.each_with_index do |bookmark, index|
        puts "  #{index + 1}. #{bookmark[:name]} (#{bookmark[:path]})"
      end
      
      print ConfigLoader.message('bookmark.input_number') || "Enter number to remove: "
      input = STDIN.gets.chomp
      number = input.to_i
      
      if number > 0 && number <= bookmarks.length
        bookmark_to_remove = bookmarks[number - 1]
        if @bookmark.remove(bookmark_to_remove[:name])
          puts "\n#{ConfigLoader.message('bookmark.removed') || 'Bookmark removed'}: #{bookmark_to_remove[:name]}"
        else
          puts "\n#{ConfigLoader.message('bookmark.remove_failed') || 'Failed to remove bookmark'}"
        end
      else
        puts "\n#{ConfigLoader.message('bookmark.invalid_number') || 'Invalid number'}"
      end
      
      print ConfigLoader.message('keybind.press_any_key') || 'Press any key to continue...'
      STDIN.getch
      true
    end

    def list_bookmarks_interactive
      bookmarks = @bookmark.list
      
      if bookmarks.empty?
        puts "\n#{ConfigLoader.message('bookmark.no_bookmarks') || 'No bookmarks found'}"
        print ConfigLoader.message('keybind.press_any_key') || 'Press any key to continue...'
        STDIN.getch
        return false
      end

      puts "\nBookmarks:"
      bookmarks.each_with_index do |bookmark, index|
        puts "  #{index + 1}. #{bookmark[:name]} (#{bookmark[:path]})"
      end
      
      print ConfigLoader.message('keybind.press_any_key') || 'Press any key to continue...'
      STDIN.getch
      true
    end

    def goto_bookmark(number)
      bookmark = @bookmark.find_by_number(number)
      
      unless bookmark
        puts "\n#{ConfigLoader.message('bookmark.not_found') || 'Bookmark not found'}: #{number}"
        print ConfigLoader.message('keybind.press_any_key') || 'Press any key to continue...'
        STDIN.getch
        return false
      end

      unless Dir.exist?(bookmark[:path])
        puts "\n#{ConfigLoader.message('bookmark.path_not_exist') || 'Bookmark path does not exist'}: #{bookmark[:path]}"
        print ConfigLoader.message('keybind.press_any_key') || 'Press any key to continue...'
        STDIN.getch
        return false
      end

      # ディレクトリに移動
      result = @directory_listing.navigate_to_path(bookmark[:path])
      if result
        @current_index = 0
        clear_filter_mode
        puts "\n#{ConfigLoader.message('bookmark.navigated') || 'Navigated to bookmark'}: #{bookmark[:name]}"
        sleep(0.5) # 短時間表示
        return true
      else
        puts "\n#{ConfigLoader.message('bookmark.navigate_failed') || 'Failed to navigate to bookmark'}: #{bookmark[:name]}"
        print ConfigLoader.message('keybind.press_any_key') || 'Press any key to continue...'
        STDIN.getch
        return false
      end
    end
  end
end
