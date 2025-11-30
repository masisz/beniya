# frozen_string_literal: true

require 'test_helper'
require 'minitest/autorun'

class TestCommandModeUI < Minitest::Test
  def setup
    # プラグインマネージャーをリセット
    Beniya::PluginManager.instance_variable_set(:@plugins, [])
    Beniya::PluginManager.instance_variable_set(:@enabled_plugins, nil)

    # テスト用プラグインを作成
    @test_plugin = Class.new(Beniya::Plugin) do
      def name
        "TestPlugin"
      end

      def description
        "テスト用プラグイン"
      end

      def commands
        {
          hello: method(:say_hello),
          help: method(:show_help),
          health: method(:health_check)
        }
      end

      private

      def say_hello
        "Hello from TestPlugin!"
      end

      def show_help
        "Help information"
      end

      def health_check
        "Health: OK"
      end
    end

    # プラグインを登録
    Beniya::Plugins.const_set(:TestPlugin, @test_plugin)
    Beniya::PluginManager.register(@test_plugin)
    Beniya::PluginManager.instance_variable_set(:@enabled_plugins, nil)

    @command_mode = Beniya::CommandMode.new
    @dialog_renderer = Beniya::DialogRenderer.new
    @command_mode_ui = Beniya::CommandModeUI.new(@command_mode, @dialog_renderer)
  end

  def teardown
    # テスト後のクリーンアップ
    Beniya::PluginManager.instance_variable_set(:@plugins, [])
    Beniya::PluginManager.instance_variable_set(:@enabled_plugins, nil)

    # テスト用プラグインを削除
    if Beniya::Plugins.const_defined?(:TestPlugin, false)
      Beniya::Plugins.send(:remove_const, :TestPlugin)
    end
  end

  # === Tab補完機能のテスト ===

  def test_command_mode_ui_class_exists
    assert defined?(Beniya::CommandModeUI), "Beniya::CommandModeUI クラスが定義されていません"
  end

  def test_autocomplete_no_input
    # 入力がない場合、全てのコマンドを返す
    suggestions = @command_mode_ui.autocomplete("")

    assert_includes suggestions, "hello"
    assert_includes suggestions, "help"
    assert_includes suggestions, "health"
  end

  def test_autocomplete_partial_match
    # 部分一致で補完候補を返す
    suggestions = @command_mode_ui.autocomplete("he")

    assert_includes suggestions, "hello"
    assert_includes suggestions, "help"
    assert_includes suggestions, "health"
  end

  def test_autocomplete_exact_prefix
    # より具体的なプレフィックスで絞り込み
    suggestions = @command_mode_ui.autocomplete("hel")

    assert_includes suggestions, "hello"
    assert_includes suggestions, "help"
    refute_includes suggestions, "health"
  end

  def test_autocomplete_single_match
    # 一つだけマッチする場合
    suggestions = @command_mode_ui.autocomplete("hello")

    assert_equal ["hello"], suggestions
  end

  def test_autocomplete_no_match
    # マッチするものがない場合
    suggestions = @command_mode_ui.autocomplete("xyz")

    assert_empty suggestions
  end

  def test_complete_command_single_match
    # 一つだけマッチする場合は自動補完
    completed = @command_mode_ui.complete_command("hello")

    assert_equal "hello", completed
  end

  def test_complete_command_multiple_matches
    # 複数マッチする場合は共通部分まで補完
    completed = @command_mode_ui.complete_command("he")

    # "hello", "help", "health" の共通プレフィックスは "he"
    assert_equal "he", completed
  end

  def test_complete_command_no_match
    # マッチしない場合は元の入力を返す
    completed = @command_mode_ui.complete_command("xyz")

    assert_equal "xyz", completed
  end

  # === フローティングウィンドウ表示のテスト ===

  def test_show_result_success
    # 成功メッセージの表示
    result = "Command executed successfully!"

    # モック化してメソッドが呼ばれることを確認
    draw_called = false
    clear_called = false

    @dialog_renderer.stub :draw_floating_window, ->(x, y, w, h, title, content, opts) {
      draw_called = true
      assert_equal "コマンド実行結果", title
      assert_includes content, result
    } do
      @dialog_renderer.stub :clear_area, ->(*) { clear_called = true } do
        STDIN.stub :getch, "\r" do
          @command_mode_ui.show_result(result)
        end
      end
    end

    assert draw_called, "draw_floating_window が呼ばれていません"
    assert clear_called, "clear_area が呼ばれていません"
  end

  def test_show_result_error
    # エラーメッセージの表示
    result = "⚠️  コマンドが見つかりません: xyz"

    draw_called = false

    @dialog_renderer.stub :draw_floating_window, ->(x, y, w, h, title, content, opts) {
      draw_called = true
      assert_includes content, result
      # エラーの場合は色が変わることを確認
      assert_equal "\e[31m", opts[:border_color] if result.include?("⚠️")
    } do
      @dialog_renderer.stub :clear_area, ->(*) {} do
        STDIN.stub :getch, "\r" do
          @command_mode_ui.show_result(result)
        end
      end
    end

    assert draw_called, "draw_floating_window が呼ばれていません"
  end

  def test_show_result_multiline
    # 複数行の結果表示
    result = "Line 1\nLine 2\nLine 3"

    draw_called = false

    @dialog_renderer.stub :draw_floating_window, ->(x, y, w, h, title, content, opts) {
      draw_called = true
      # 空行 + Line1 + Line2 + Line3 + 空行 + "Press any key to close"
      # 空行でない行は 4行（結果3行 + プロンプト1行）
      assert_equal 4, content.select { |line| !line.empty? }.length
    } do
      @dialog_renderer.stub :clear_area, ->(*) {} do
        STDIN.stub :getch, "\r" do
          @command_mode_ui.show_result(result)
        end
      end
    end

    assert draw_called, "draw_floating_window が呼ばれていません"
  end

  def test_show_result_nil
    # nil の場合は何も表示しない
    draw_called = false

    @dialog_renderer.stub :draw_floating_window, ->(*) { draw_called = true } do
      @command_mode_ui.show_result(nil)
    end

    refute draw_called, "nil の場合は draw_floating_window を呼んではいけません"
  end

  def test_show_result_empty_string
    # 空文字列の場合は何も表示しない
    draw_called = false

    @dialog_renderer.stub :draw_floating_window, ->(*) { draw_called = true } do
      @command_mode_ui.show_result("")
    end

    refute draw_called, "空文字列の場合は draw_floating_window を呼んではいけません"
  end

  # === 統合テスト ===

  def test_prompt_command_with_autocomplete
    # Tab キーでの補完動作をシミュレート
    # これは実際のキー入力をモックするのが難しいため、
    # autocomplete メソッドが正しく動作することを確認

    # 補完候補があることを確認
    suggestions = @command_mode_ui.autocomplete("he")
    assert suggestions.length > 1

    # 補完が適用されることを確認
    completed = @command_mode_ui.complete_command("he")
    assert_equal "he", completed # 共通プレフィックス
  end

  def test_command_mode_ui_initialization
    # CommandModeUI が正しく初期化できることを確認
    ui = Beniya::CommandModeUI.new(@command_mode, @dialog_renderer)

    refute_nil ui
    assert_respond_to ui, :autocomplete
    assert_respond_to ui, :complete_command
    assert_respond_to ui, :show_result
  end
end
