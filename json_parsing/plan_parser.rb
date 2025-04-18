PLAN_PARSER = {
  give_tools_overview: false,
  schema: {
    type: 'object',
    properties: {
      high_level_plan: { type: 'string' },
      next_step: { type: 'string' },
    },
    required: %w[high_level_plan next_step]
  },
  prompt: <<~PROMPT
    Identify the high-level-plan, and the next-step. Don't worry about understanding the context of this, just identify the two groups of strings
    and format them into JSON as-is. Don't summarize or change the text in any way - your only job is to convert the text into JSON.
  PROMPT
}
