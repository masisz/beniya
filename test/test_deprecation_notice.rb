# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/beniya/deprecation_notice'

module Beniya
  class TestDeprecationNotice < Minitest::Test
    def setup
      @notice = DeprecationNotice.new
    end

    def test_initialize
      assert_instance_of DeprecationNotice, @notice
    end

    def test_should_show_returns_boolean
      result = @notice.should_show?
      assert [true, false].include?(result)
    end

    def test_mark_as_shown_changes_state
      # 初回は表示すべき状態
      initial_state = @notice.should_show?

      # 表示済みにマーク
      @notice.mark_as_shown

      # 表示済みフラグが設定される
      assert_equal false, @notice.should_show?
    end

    def test_content_returns_array
      content = @notice.content
      assert_instance_of Array, content
      assert content.length > 0
    end

    def test_content_includes_rufio_message
      content = @notice.content
      # rufioへの移行メッセージが含まれているか
      assert content.any? { |line| line.include?('rufio') || line.include?('Rufio') }
    end

    def test_title_returns_string
      title = @notice.title
      assert_instance_of String, title
      assert title.length > 0
    end
  end
end
