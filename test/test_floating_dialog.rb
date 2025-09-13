#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'test_helper'

class TestFloatingDialog < Minitest::Test
  def setup
    @keybind_handler = Beniya::KeybindHandler.new
  end

  def test_display_width_calculation
    # ASCII文字のテスト
    assert_equal 5, @keybind_handler.send(:display_width, "Hello")
    
    # 日本語文字のテスト（全角文字は幅2として計算）
    assert_equal 6, @keybind_handler.send(:display_width, "こんにちは")  # 3文字 × 2 = 6
    
    # 混在文字列のテスト
    assert_equal 9, @keybind_handler.send(:display_width, "Hello世界")  # 5 + 2*2 = 9
  end

  def test_get_screen_center_calculation
    x, y = @keybind_handler.send(:get_screen_center, 40, 8)
    
    # 中央位置が正の値であることを確認
    assert x > 0, "X position should be positive"
    assert y > 0, "Y position should be positive"
    
    # 最小値が1であることを確認
    assert x >= 1, "X position should be at least 1"
    assert y >= 1, "Y position should be at least 1"
  end

  def test_floating_dialog_methods_exist
    # 必要なメソッドが定義されていることを確認
    assert_respond_to @keybind_handler, :display_width, "display_width method should exist"
    assert_respond_to @keybind_handler, :get_screen_center, "get_screen_center method should exist" 
    assert_respond_to @keybind_handler, :draw_floating_window, "draw_floating_window method should exist"
    assert_respond_to @keybind_handler, :clear_floating_window_area, "clear_floating_window_area method should exist"
  end

  def test_show_deletion_result_with_success
    # 成功時のメソッド呼び出しテスト（実際の画面出力はしない）
    # モック化して副作用をテスト
    @keybind_handler.stub :draw_floating_window, nil do
      @keybind_handler.stub :clear_floating_window_area, nil do
        # STDINをモック化
        STDIN.stub :getch, 'y' do
          # メソッドが正常に呼び出せることを確認
          assert_nothing_raised do
            @keybind_handler.send(:show_deletion_result, 3, 3, [])
          end
        end
      end
    end
  end

  def test_show_deletion_result_with_errors  
    error_messages = ["file1.txt: Permission denied", "file2.txt: File not found"]
    
    # エラー付きの結果表示テスト
    @keybind_handler.stub :draw_floating_window, nil do
      @keybind_handler.stub :clear_floating_window_area, nil do
        STDIN.stub :getch, 'n' do
          assert_nothing_raised do
            @keybind_handler.send(:show_deletion_result, 1, 3, error_messages)
          end
        end
      end
    end
  end
end

# テスト実行
if __FILE__ == $0
  puts "=== Floating Dialog Tests ==="
  Minitest.run([])
  puts "=== Tests Completed ==="
end