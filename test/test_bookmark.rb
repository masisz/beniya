# frozen_string_literal: true

require_relative 'test_helper'
require_relative '../lib/beniya/bookmark'

# 明示的にMinitestを実行
Minitest.autorun

module Beniya
  class TestBookmark < Minitest::Test
    def setup
      @test_config_dir = File.join(Dir.tmpdir, 'beniya_test_config')
      @test_config_file = File.join(@test_config_dir, 'bookmarks.json')
      
      # テスト用の設定ディレクトリを作成
      FileUtils.mkdir_p(@test_config_dir)
      
      # 既存のブックマークファイルがあれば削除
      FileUtils.rm_f(@test_config_file)
      
      @bookmark = Bookmark.new(@test_config_file)
    end

    def teardown
      # テスト後にクリーンアップ
      FileUtils.rm_rf(@test_config_dir) if Dir.exist?(@test_config_dir)
    end

    def test_initialize_creates_empty_bookmarks
      assert_empty @bookmark.list
    end

    def test_add_bookmark
      path = '/home/user/documents'
      name = 'Documents'
      
      result = @bookmark.add(path, name)
      
      assert result
      assert_equal 1, @bookmark.list.length
      assert_equal path, @bookmark.list.first[:path]
      assert_equal name, @bookmark.list.first[:name]
    end

    def test_add_bookmark_with_duplicate_name
      path1 = '/home/user/documents'
      path2 = '/home/user/downloads'
      name = 'Documents'
      
      @bookmark.add(path1, name)
      result = @bookmark.add(path2, name)
      
      refute result
      assert_equal 1, @bookmark.list.length
    end

    def test_add_bookmark_with_duplicate_path
      path = '/home/user/documents'
      name1 = 'Documents'
      name2 = 'Docs'
      
      @bookmark.add(path, name1)
      result = @bookmark.add(path, name2)
      
      refute result
      assert_equal 1, @bookmark.list.length
    end

    def test_remove_bookmark_by_name
      path = '/home/user/documents'
      name = 'Documents'
      
      @bookmark.add(path, name)
      result = @bookmark.remove(name)
      
      assert result
      assert_empty @bookmark.list
    end

    def test_remove_nonexistent_bookmark
      result = @bookmark.remove('NonExistent')
      
      refute result
      assert_empty @bookmark.list
    end

    def test_get_bookmark_path
      path = '/home/user/documents'
      name = 'Documents'
      
      @bookmark.add(path, name)
      result = @bookmark.get_path(name)
      
      assert_equal path, result
    end

    def test_get_nonexistent_bookmark_path
      result = @bookmark.get_path('NonExistent')
      
      assert_nil result
    end

    def test_find_by_number
      paths = ['/home/user/documents', '/home/user/downloads', '/home/user/desktop']
      names = ['Documents', 'Downloads', 'Desktop']
      
      paths.each_with_index do |path, index|
        @bookmark.add(path, names[index])
      end
      
      # 番号は1から始まる
      result = @bookmark.find_by_number(1)
      assert_equal paths[0], result[:path]
      assert_equal names[0], result[:name]
      
      result = @bookmark.find_by_number(2)
      assert_equal paths[1], result[:path]
      assert_equal names[1], result[:name]
      
      result = @bookmark.find_by_number(3)
      assert_equal paths[2], result[:path]
      assert_equal names[2], result[:name]
    end

    def test_find_by_invalid_number
      @bookmark.add('/home/user/documents', 'Documents')
      
      result = @bookmark.find_by_number(0)
      assert_nil result
      
      result = @bookmark.find_by_number(10)
      assert_nil result
      
      result = @bookmark.find_by_number(-1)
      assert_nil result
    end

    def test_save_and_load_persistence
      path = '/home/user/documents'
      name = 'Documents'
      
      @bookmark.add(path, name)
      @bookmark.save
      
      # 新しいインスタンスを作成して読み込み
      new_bookmark = Bookmark.new(@test_config_file)
      new_bookmark.load
      
      assert_equal 1, new_bookmark.list.length
      assert_equal path, new_bookmark.list.first[:path]
      assert_equal name, new_bookmark.list.first[:name]
    end

    def test_load_from_nonexistent_file
      nonexistent_file = File.join(@test_config_dir, 'nonexistent.json')
      bookmark = Bookmark.new(nonexistent_file)
      
      result = bookmark.load
      
      assert result  # load should succeed with empty list
      assert_empty bookmark.list
    end

    def test_load_from_invalid_json
      # 不正なJSONファイルを作成
      File.write(@test_config_file, 'invalid json content')
      
      result = @bookmark.load
      
      assert result  # load should succeed with empty list
      assert_empty @bookmark.list
    end

    def test_max_bookmarks_limit
      # 最大9個のブックマークを追加
      9.times do |i|
        result = @bookmark.add("/path/#{i}", "bookmark#{i}")
        assert result
      end
      
      # 10個目は追加できない
      result = @bookmark.add('/path/10', 'bookmark10')
      refute result
      assert_equal 9, @bookmark.list.length
    end

    def test_list_returns_sorted_bookmarks
      paths = ['/z/path', '/a/path', '/m/path']
      names = ['ZFolder', 'AFolder', 'MFolder']
      
      # 順序バラバラで追加
      @bookmark.add(paths[0], names[0])
      @bookmark.add(paths[1], names[1])
      @bookmark.add(paths[2], names[2])
      
      list = @bookmark.list
      
      # 名前順でソートされている
      assert_equal 'AFolder', list[0][:name]
      assert_equal 'MFolder', list[1][:name]
      assert_equal 'ZFolder', list[2][:name]
    end
  end
end