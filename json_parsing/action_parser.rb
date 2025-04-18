ACTION_PARSER = {
  give_tools_overview: true,
  schema: {
    type: 'object',
    properties: {
      action: { type: 'string', enum: %w[ TOOL_CALL RESPONSE ] },
      raw: { type: 'string' },
      tool_call: {
        type: 'object',
        properties: {
          tool_name: { type: 'string' },
          arguments: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                name: { type: 'string' },
                value: { type: 'string' },
              },
              required: %w[name value]
            }
          }
        },
        required: %w[tool_name arguments]
      }
    },
    required: %w[action raw]
  },
  prompt: <<~PROMPT
    1. The "raw" property should contain the full text you are parsing.
    2. The "action" property can be identified by searching the text for the keyword "TOOL_CALL". If there is no "TOOL_CALL" keyword, then it is by default a "RESPONSE".
        Don't try to be clever here by reading the context. If the text contains the word "TOOL_CALL", then the action is "TOOL_CALL". Otherwise, it is "RESPONSE".
    3. The "tool_call" property MUST be provided when the "action" is TOOL_CALL. You must extract the tool name and arguments from the text. This will include the name of the tool being called,
       as well as a key-value pair for each argument that the tool requires.
  PROMPT
}
