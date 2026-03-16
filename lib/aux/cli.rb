# frozen_string_literal: true

require "thor"
require_relative "colorize"
require_relative "commands/pr"

module Aux
  class CLI < Thor
    namespace ""

    def self.exit_on_failure?
      true
    end

    desc "help [COMMAND]", "Describe available commands or one specific command"
    def help(command = nil, subcommand: false)
      super
    end

    desc "pr", "Prepare a GitHub PR (checks branch sync with remote)"
    def pr
      Commands::Pr.new.run
    end
  end
end
