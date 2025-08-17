# frozen_string_literal: true

require_relative "test_helper"

class TestConfigLoader < Minitest::Test
  def setup
    # テスト前にキャッシュをクリア
    Beniya::ConfigLoader.instance_variable_set(:@config, nil)
  end

  def teardown
    # テスト後にもキャッシュをクリア
    Beniya::ConfigLoader.instance_variable_set(:@config, nil)
  end

  def test_load_default_config_when_no_file_exists
    # 設定ファイルが存在しない場合のテスト
    # パスを一時的に存在しないパスに変更
    original_path = Beniya::ConfigLoader::CONFIG_PATH
    Beniya::ConfigLoader.const_set(:CONFIG_PATH, "/tmp/nonexistent_config.rb")
    
    config = Beniya::ConfigLoader.load_config
    
    # デフォルト設定が返されることを確認
    assert_instance_of Hash, config
    assert config.key?(:applications)
    assert config.key?(:colors)
    assert config.key?(:keybinds)
    
    # アプリケーションの設定を確認
    applications = config[:applications]
    assert_equal 'code', applications[%w[txt md rb py js html css json xml yaml yml]]
    assert_equal 'open', applications[:default]
    
    # 元のパスに戻す
    Beniya::ConfigLoader.const_set(:CONFIG_PATH, original_path)
  end

  def test_applications_method
    applications = Beniya::ConfigLoader.applications
    assert_instance_of Hash, applications
    assert applications.key?(%w[txt md rb py js html css json xml yaml yml])
  end

  def test_colors_method
    colors = Beniya::ConfigLoader.colors
    assert_instance_of Hash, colors
    assert_equal :blue, colors[:directory]
    assert_equal :white, colors[:file]
  end

  def test_keybinds_method
    keybinds = Beniya::ConfigLoader.keybinds
    assert_instance_of Hash, keybinds
    assert_equal %w[q ESC], keybinds[:quit]
    assert_equal %w[o SPACE], keybinds[:open_file]
  end

  def test_reload_config
    # 最初の読み込み
    config1 = Beniya::ConfigLoader.load_config
    
    # リロード
    config2 = Beniya::ConfigLoader.reload_config!
    
    # 設定が再読み込みされることを確認（同じ内容でも問題ない）
    assert_equal config1, config2
  end
end