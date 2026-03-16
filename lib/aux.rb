# frozen_string_literal: true

require_relative "aux/cli"

$PROGRAM_NAME = "aux"
Aux::CLI.start(ARGV)
