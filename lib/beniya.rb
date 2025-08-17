# frozen_string_literal: true

require_relative "beniya/version"
require_relative "beniya/config"
require_relative "beniya/config_loader"
require_relative "beniya/color_helper"
require_relative "beniya/directory_listing"
require_relative "beniya/keybind_handler"
require_relative "beniya/file_preview"
require_relative "beniya/terminal_ui"
require_relative "beniya/application"
require_relative "beniya/file_opener"
require_relative "beniya/health_checker"

module Beniya
  class Error < StandardError; end
end