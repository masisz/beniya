# frozen_string_literal: true

require_relative "beniya/version"
require_relative "beniya/config"
require_relative "beniya/config_loader"
require_relative "beniya/color_helper"
require_relative "beniya/directory_listing"
require_relative "beniya/filter_manager"
require_relative "beniya/selection_manager"
require_relative "beniya/file_operations"
require_relative "beniya/bookmark_manager"
require_relative "beniya/bookmark"
require_relative "beniya/zoxide_integration"
require_relative "beniya/dialog_renderer"
require_relative "beniya/text_utils"
require_relative "beniya/logger"
require_relative "beniya/keybind_handler"
require_relative "beniya/file_preview"
require_relative "beniya/terminal_ui"
require_relative "beniya/application"
require_relative "beniya/file_opener"
require_relative "beniya/health_checker"

# プラグインシステム
require_relative "beniya/plugin_config"
require_relative "beniya/plugin"
require_relative "beniya/plugin_manager"

module Beniya
  class Error < StandardError; end
end