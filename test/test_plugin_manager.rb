# frozen_string_literal: true

require 'test_helper'

class TestPluginManager < Minitest::Test
  def setup
    # テスト前にプラグインリストをクリア
    Beniya::PluginManager.instance_variable_set(:@plugins, [])
    Beniya::PluginManager.instance_variable_set(:@enabled_plugins, nil)

    # テスト用の一時ディレクトリを作成
    @temp_dir = Dir.mktmpdir
    @user_plugins_dir = File.join(@temp_dir, '.beniya', 'plugins')
    @config_path = File.join(@temp_dir, '.beniya', 'config.yml')
    FileUtils.mkdir_p(@user_plugins_dir)

    # 元のHOME環境変数を保存
    @original_home = ENV['HOME']
    ENV['HOME'] = @temp_dir
  end

  def teardown
    # HOME環境変数を復元
    ENV['HOME'] = @original_home

    # 一時ディレクトリを削除
    FileUtils.rm_rf(@temp_dir)

    # プラグインリストをクリア
    Beniya::PluginManager.instance_variable_set(:@plugins, [])
    Beniya::PluginManager.instance_variable_set(:@enabled_plugins, nil)

    # テスト用に定義したクラスを削除
    cleanup_test_classes
  end

  def test_plugin_manager_exists
    assert defined?(Beniya::PluginManager), "Beniya::PluginManager クラスが定義されていません"
  end

  def test_plugins_returns_array
    assert_kind_of Array, Beniya::PluginManager.plugins
  end

  def test_register_plugin
    plugin_class = Class.new(Beniya::Plugin) do
      def name
        "TestPlugin"
      end
    end

    Beniya::PluginManager.register(plugin_class)
    assert_includes Beniya::PluginManager.plugins, plugin_class
  end

  def test_register_same_plugin_twice_does_not_duplicate
    plugin_class = Class.new(Beniya::Plugin) do
      def name
        "TestPlugin"
      end
    end

    Beniya::PluginManager.register(plugin_class)
    Beniya::PluginManager.register(plugin_class)

    # 同じプラグインが2回登録されないことを確認
    assert_equal 1, Beniya::PluginManager.plugins.count(plugin_class)
  end

  def test_load_builtin_plugins
    # 本体同梱プラグインのディレクトリを確認
    builtin_plugins_dir = File.expand_path('../../lib/beniya/plugins', __dir__)

    # プラグインディレクトリが存在する、または存在しない場合もエラーにならないことを確認
    assert_nothing_raised do
      Beniya::PluginManager.send(:load_builtin_plugins)
    end
  end

  def test_load_user_plugins_from_home_directory
    # テスト用のユーザープラグインを作成
    plugin_content = <<~RUBY
      module Beniya
        module Plugins
          class UserTestPlugin < Plugin
            def name
              "UserTestPlugin"
            end
          end
        end
      end
    RUBY

    File.write(File.join(@user_plugins_dir, 'user_test_plugin.rb'), plugin_content)

    # ユーザープラグインを読み込み
    Beniya::PluginManager.send(:load_user_plugins)

    # プラグインが登録されていることを確認
    plugin_classes = Beniya::PluginManager.plugins.map(&:name)
    assert_includes plugin_classes, "Beniya::Plugins::UserTestPlugin"
  end

  def test_load_user_plugins_directory_not_exist
    # ユーザープラグインディレクトリを削除
    FileUtils.rm_rf(@user_plugins_dir)

    # ディレクトリが存在しない場合もエラーにならない
    assert_nothing_raised do
      Beniya::PluginManager.send(:load_user_plugins)
    end
  end

  def test_load_all_loads_both_builtin_and_user_plugins
    # テスト用のユーザープラグインを作成
    plugin_content = <<~RUBY
      module Beniya
        module Plugins
          class AnotherUserPlugin < Plugin
            def name
              "AnotherUserPlugin"
            end
          end
        end
      end
    RUBY

    File.write(File.join(@user_plugins_dir, 'another_user_plugin.rb'), plugin_content)

    # 全プラグインを読み込み
    assert_nothing_raised do
      Beniya::PluginManager.load_all
    end
  end

  def test_enabled_plugins_returns_array_of_plugin_instances
    # テスト用のプラグインを登録
    plugin_class = Class.new(Beniya::Plugin) do
      def name
        "EnabledTestPlugin"
      end
    end

    # プラグイン名を定数として定義
    Beniya::Plugins.const_set(:EnabledTestPlugin, plugin_class)
    Beniya::PluginManager.register(plugin_class)

    enabled = Beniya::PluginManager.enabled_plugins
    assert_kind_of Array, enabled
  end

  def test_enabled_plugins_respects_config
    # テスト用のプラグインを登録
    plugin1_class = Class.new(Beniya::Plugin) do
      def name
        "EnabledPlugin"
      end
    end

    plugin2_class = Class.new(Beniya::Plugin) do
      def name
        "DisabledPlugin"
      end
    end

    Beniya::Plugins.const_set(:EnabledPlugin, plugin1_class)
    Beniya::Plugins.const_set(:DisabledPlugin, plugin2_class)

    Beniya::PluginManager.register(plugin1_class)
    Beniya::PluginManager.register(plugin2_class)

    # config.ymlを作成
    config_content = <<~YAML
      plugins:
        enabledplugin:
          enabled: true
        disabledplugin:
          enabled: false
    YAML

    FileUtils.mkdir_p(File.dirname(@config_path))
    File.write(@config_path, config_content)

    # Configをリロード
    Beniya::PluginConfig.instance_variable_set(:@config, nil)
    Beniya::PluginConfig.load

    # enabled_pluginsを取得
    Beniya::PluginManager.instance_variable_set(:@enabled_plugins, nil)
    enabled = Beniya::PluginManager.enabled_plugins

    # EnabledPluginのみが含まれることを確認
    enabled_names = enabled.map(&:name)
    assert_includes enabled_names, "EnabledPlugin"
    refute_includes enabled_names, "DisabledPlugin"
  end

  def test_plugin_with_missing_dependency_is_skipped_with_warning
    # 存在しないgemに依存するプラグインを作成
    plugin_content = <<~RUBY
      module Beniya
        module Plugins
          class PluginWithMissingGem < Plugin
            requires 'nonexistent_gem_xyz_123'

            def name
              "PluginWithMissingGem"
            end
          end
        end
      end
    RUBY

    File.write(File.join(@user_plugins_dir, 'plugin_with_missing_gem.rb'), plugin_content)

    # 警告が出力されることを確認（標準エラー出力をキャプチャ）
    _out, err = capture_io do
      Beniya::PluginManager.load_all
    end

    # 警告メッセージが含まれることを確認
    assert_match(/⚠️/, err)

    # enabled_pluginsから除外されることを確認
    Beniya::PluginManager.instance_variable_set(:@enabled_plugins, nil)
    enabled = Beniya::PluginManager.enabled_plugins
    enabled_names = enabled.map(&:name)
    refute_includes enabled_names, "PluginWithMissingGem"
  end

  def test_plugin_load_error_is_handled_gracefully
    # 構文エラーのあるプラグインを作成
    plugin_content = <<~RUBY
      module Beniya
        module Plugins
          class BrokenPlugin < Plugin
            # 構文エラー
            def name
              "BrokenPlugin"
            # endが足りない
        end
      end
    RUBY

    File.write(File.join(@user_plugins_dir, 'broken_plugin.rb'), plugin_content)

    # エラーが発生してもbeniyaは起動継続する
    assert_nothing_raised do
      Beniya::PluginManager.load_all
    end
  end

  private

  def cleanup_test_classes
    [
      :EnabledTestPlugin,
      :EnabledPlugin,
      :DisabledPlugin,
      :UserTestPlugin,
      :AnotherUserPlugin,
      :PluginWithMissingGem,
      :BrokenPlugin
    ].each do |class_name|
      if Beniya::Plugins.const_defined?(class_name)
        Beniya::Plugins.send(:remove_const, class_name)
      end
    end
  end
end
