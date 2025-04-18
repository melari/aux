class Tools::Weather
  def self.tool_name
    'get_current_weather'
  end

  def run(location:, temperature_unit:)
    "The weather in #{location} is 25 degrees #{temperature_unit} 🎉"
  end

  def manifest
    @manifest ||= Ollama::Tool.new(
      type: 'function',
      function: Ollama::Tool::Function.new(
        name: self.class.tool_name,
        description: 'Get the current weather for a location',
        parameters: Ollama::Tool::Function::Parameters.new(
          type: 'object',
          properties: {
            location: Ollama::Tool::Function::Parameters::Property.new(
              type: 'string',
              description: 'The location to get the weather for, e.g. San Francisco, CA'
            ),
            temperature_unit: Ollama::Tool::Function::Parameters::Property.new(
              type: 'string',
              description: "The unit to return the temperature in, either 'celsius' or 'fahrenheit'",
              enum: %w[ celsius fahrenheit ]
            ),
          },
          required: %w[ location temperature_unit ]
        )
      )
    )
  end
end
