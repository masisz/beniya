# frozen_string_literal: true

module Beniya
  class KeybindHandler
    attr_reader :current_index

    def initialize
      @current_index = 0
      @directory_listing = nil
      @terminal_ui = nil
      @file_opener = FileOpener.new
      @filter_mode = false
      @filter_query = ""
      @filtered_entries = []
      @original_entries = []
    end

    def set_directory_listing(directory_listing)
      @directory_listing = directory_listing
      @current_index = 0
    end

    def set_terminal_ui(terminal_ui)
      @terminal_ui = terminal_ui
    end

    def handle_key(key)
      return false unless @directory_listing

      # フィルターモード中は他のキーバインドを無効化
      if @filter_mode
        return handle_filter_input(key)
      end

      case key
      when 'j'
        move_down
      when 'k'
        move_up
      when 'h'
        navigate_parent
      when 'l', "\r", "\n"  # l, Enter
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
      when ' '  # Space - disabled for future functionality
        false
      when "\e"  # ESC
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
      else
        false  # #{ConfigLoader.message('keybind.invalid_key')}
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

    def filter_query
      @filter_query
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

      if entry[:type] == "directory"
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
      
      if entry[:type] == "file"
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
      true  # request exit
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
      system("which fzf > /dev/null 2>&1")
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
      selected_result = IO.popen("fzf", "r+") do |fzf|
        fzf.write(search_results)
        fzf.close_write
        fzf.read.strip
      end
      
      # extract file path and line number from selected result
      if !selected_result.empty? && selected_result.match(/^(.+?):(\d+):/)
        file_path = $1
        line_number = $2.to_i
        full_path = File.expand_path(file_path, current_path)
        
        if File.exist?(full_path)
          @file_opener.open_file_with_line(full_path, line_number)
        end
      end
      
      true
    end

    def rga_available?
      system("which rga > /dev/null 2>&1")
    end

    def start_filter_mode
      @filter_mode = true
      @filter_query = ""
      @original_entries = @directory_listing.list_entries.dup
      @filtered_entries = @original_entries.dup
      @current_index = 0
      true
    end

    def handle_filter_input(key)
      case key
      when "\e"  # ESC - フィルタをクリアして通常モードに戻る
        clear_filter_mode
      when "\r", "\n"  # Enter - フィルタを維持して通常モードに戻る
        exit_filter_mode_keep_filter
      when "\u007f", "\b"  # Backspace
        if @filter_query.length > 0
          @filter_query = @filter_query[0...-1]
          apply_filter
        else
          clear_filter_mode
        end
      else
        # printable characters (英数字、記号、日本語文字など)
        if key.length == 1 && key.ord >= 32 && key.ord < 127  # ASCII printable
          @filter_query += key
          apply_filter
        elsif key.bytesize > 1  # Multi-byte characters (Japanese, etc.)
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
      @filter_query = ""
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
      rescue => e
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
      rescue => e
        puts "\n#{ConfigLoader.message('keybind.creation_error')}: #{e.message}"
        print ConfigLoader.message('keybind.press_any_key')
        STDIN.getch
        false
      end
    end
  end
end