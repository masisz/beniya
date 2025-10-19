# frozen_string_literal: true

module Beniya
  # Text utility methods for display width calculation and string manipulation
  # Handles multi-byte characters (Japanese, etc.) correctly
  module TextUtils
    module_function

    # Character width constants
    FULLWIDTH_CHAR_WIDTH = 2
    HALFWIDTH_CHAR_WIDTH = 1
    MULTIBYTE_THRESHOLD = 1

    # Truncation constants
    ELLIPSIS_MIN_WIDTH = 3
    ELLIPSIS = '...'

    # Line break constants
    BREAK_POINT_THRESHOLD = 0.5  # Break after 50% of max_width

    # Calculate display width of a string
    # Full-width characters (Japanese, etc.) count as 2, half-width as 1
    def display_width(string)
      string.each_char.map do |char|
        case char
        when /[\u3000-\u303F\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF\uFF00-\uFFEF]/
          FULLWIDTH_CHAR_WIDTH  # Japanese characters (hiragana, katakana, kanji, full-width symbols)
        when /[\u0020-\u007E]/
          HALFWIDTH_CHAR_WIDTH  # ASCII characters
        else
          char.bytesize > MULTIBYTE_THRESHOLD ? FULLWIDTH_CHAR_WIDTH : HALFWIDTH_CHAR_WIDTH
        end
      end.sum
    end

    # Truncate string to fit within max_width
    def truncate_to_width(string, max_width)
      return string if display_width(string) <= max_width

      result = ''
      current_width = 0

      string.each_char do |char|
        char_width = display_width(char)
        break if current_width + char_width > max_width

        result += char
        current_width += char_width
      end

      # Add ellipsis if there's room
      result += ELLIPSIS if max_width >= ELLIPSIS_MIN_WIDTH && current_width <= max_width - ELLIPSIS_MIN_WIDTH
      result
    end

    # Pad string to target_width with spaces
    def pad_string_to_width(string, target_width)
      current_width = display_width(string)
      if current_width >= target_width
        truncate_to_width(string, target_width)
      else
        string + ' ' * (target_width - current_width)
      end
    end

    # Find the best break point for wrapping text within max_width
    def find_break_point(line, max_width)
      return line.length if display_width(line) <= max_width

      current_width = 0
      best_break_point = 0
      space_break_point = nil
      punct_break_point = nil

      line.each_char.with_index do |char, index|
        char_width = display_width(char)
        break if current_width + char_width > max_width

        current_width += char_width
        best_break_point = index + 1

        # Record break point at space
        space_break_point = index + 1 if char == ' ' && current_width > max_width * BREAK_POINT_THRESHOLD

        # Record break point at Japanese punctuation
        punct_break_point = index + 1 if char.match?(/[、。，．！？]/) && current_width > max_width * BREAK_POINT_THRESHOLD
      end

      space_break_point || punct_break_point || best_break_point
    end
  end
end
