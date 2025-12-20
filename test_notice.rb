#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/beniya'

puts "Testing deprecation notice..."
puts "Checking if notice should show: #{Beniya::DeprecationNotice.new.should_show?}"

# Simulate terminal UI setup
system('tput smcup')  # alternate screen
system('tput civis')  # cursor invisible
print "\e[2J\e[H"     # clear screen

begin
  notice = Beniya::DeprecationNotice.new

  if notice.should_show?
    puts "Notice should be shown, displaying..."

    # Get screen size
    require 'io/console'
    screen_width, screen_height = IO.console.winsize.reverse

    # Calculate window dimensions
    width = [screen_width - 10, 70].min
    height = 18
    x = (screen_width - width) / 2
    y = (screen_height - height) / 2

    dialog_renderer = Beniya::DialogRenderer.new

    # Display the notice window
    dialog_renderer.draw_floating_window(
      x, y, width, height,
      notice.title,
      notice.content,
      {
        border_color: "\e[33m",  # Yellow
        title_color: "\e[1;33m", # Bold yellow
        content_color: "\e[37m"  # White
      }
    )

    # Wait for any key press
    puts "\n\n[DEBUG] Waiting for key press..."
    $stdin.getch

    # Mark as shown
    notice.mark_as_shown
    puts "\n[DEBUG] Notice marked as shown"
  else
    puts "Notice already shown, skipping"
  end
ensure
  system('tput rmcup')  # normal screen
  system('tput cnorm')  # cursor normal
end
