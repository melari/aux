require_relative 'action_parser.rb'
require_relative 'plan_parser.rb'

class JsonParse
  attr_reader :ollama, :model

  def initialize(ollama:, model:)
    @ollama = ollama
    @model = model
  end

  def parse(raw, json_parser:, tools: {}, verbose: false)
    tools_overview = <<~TOOLS
      For your reference, here are the list of tools that were available when the below text was generated:
      #{tools.values.map(&:manifest).map(&:to_json).join("\n\n")}
    TOOLS

    prompt = <<~PROMPT
      Convert the following free-form text into a JSON object.
      #{json_parser[:prompt]}

      #{json_parser[:give_tools_overview] ? tools_overview : ''}

      ====================
      Here is the text you need to convert:

      #{raw}
    PROMPT

    if verbose 
      puts "👤 #{prompt}".blue 
      puts ""
      puts "🧠 "
    end

    result = ""
    @ollama.generate(model:, stream: true, prompt:, format: json_parser[:schema]) do |response|
      result += response.response
      print response.response.brown if verbose
    end
    puts "\n\n" if verbose

    JSON.parse(result)
  end
end

