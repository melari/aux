# frozen_string_literal: true

# Simple colorize replacement to avoid copyleft dependencies
# Adds basic ANSI color support to String class

module Aux
  module Colorize
    COLORS = {
      red: "\e[31m",
      green: "\e[32m",
      yellow: "\e[33m",
      blue: "\e[34m",
      cyan: "\e[36m",
      aqua: "\e[96m",
      gray: "\e[90m",
      white: "\e[37m",
      dim: "\e[2m"
    }.freeze

    RESET = "\e[0m"

    def self.colorize_string(text, color)
      return text.to_s unless COLORS.key?(color)
      return text.to_s if ENV["NO_COLOR"] || !$stdout.tty?

      "#{COLORS[color]}#{text}#{RESET}"
    end
  end
end

class String
  def colorize(color)
    Aux::Colorize.colorize_string(self, color)
  end
end
