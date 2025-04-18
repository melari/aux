require 'ollama'
require 'debug'

require_relative 'lib/colorize'
require_relative 'lib/ollama_list'

require_relative 'json_parsing/json_parse'

require_relative 'tools/tools'

class Proto
  include Ollama

  DEEPSEEK = 'deepseek-r1:7b'
  LLAMA = 'llama3.2:latest'

  REASONING_MODEL = DEEPSEEK
  FORMATTING_MODEL = LLAMA
  MODELS = [REASONING_MODEL, FORMATTING_MODEL]

  attr_reader :verbose
  attr_reader :json_parse

  def initialize(verbose: false)
    @verbose = verbose
    @ollama = Client.new(base_url: 'http://localhost:11434')
    MODELS.each do |model|
      @ollama.pull(name: model) unless @ollama.list.models.map(&:name).include?(model)
    end

    @json_parse = JsonParse.new(ollama: @ollama, model: FORMATTING_MODEL)
  end

  def test

    tools = {
      Tools::Weather.tool_name => Tools::Weather.new,
    }


    user_request = 'What is the weather in Ottawa?'

    previous_step_result = ''
    plan = {
      'high_level_plan' => '',
      'next_step' => ''
    }

    loop do
      # ======== PLANNING PHASE ========
      history = plan['high_level_plan'].empty? ? '' : "The high-level plan you previously layed out and have been following is: #{plan['high_level_plan']}\n"

      unless plan['next_step'].empty?
        history += <<~HIST
          The last thing you tried to do was "#{plan['next_step']}", which gave you a result of: #{previous_step_result}
        HIST
      end

      instructions = <<~INSTR
        You are tasked with evaluating the plan and making any modifications necessary to ensure that the plan is still the best course of action, given what we have learned so far.
        You are to *very clearly* state two things in your response:
        - Restate the high-level plan (with or without any modifications that you'd like to make)
        - Clearly identify which step of the plan we should work on next. Make sure we have all the prerequisites to complete the step you choose.

        When responding, please follow this example format. (ie make sure to clearly use the words "HIGH-LEVEL-PLAN" and "NEXT-STEP" in your response):

        ```
        HIGH-LEVEL-PLAN:
          1. this is the first step
          2. this is the second step
          3. this is the third step

        NEXT-STEP: I will work on step x next
        ```
      INSTR

      plan = llm(user_request:, history:, instructions:, tools:, json_parser: PLAN_PARSER)


      # ======== EXECUTION PHASE ========
      history = <<~HIST
        You have already come up with a high-level plan to complete this task:

        #{plan['high_level_plan']}

        You have also identified that the next step to work on is:

        #{plan['next_step']}

      HIST

      unless previous_step_result.empty?
        history += <<~HIST
          Additionally, you have this information from the last step you completed:

          #{previous_step_result}
        HIST
      end

      instructions = <<~INSTR
        Given you have already identified the next step of the plan to work on, you are tasked with selecting the best action to complete that step.
        DO NOT action any of the other steps; we'll handle those later.

        Here are your options for what the best action could be, please choose ONE:

        A) TOOL_CALL: Use a single tool to fully complete the step.
            If you choose to us a single tool, let me know which tool to use and what parameters to use with it.
        B) RESPONSE: Respond to the user with the complete solution to their query and let them know you are done. Please let me know the answer.

        Please *clearly state* when you are using a TOOL_CALL (ie "This is a TOOL_CALL").
        You should NOT say "this is a RESPONSE" when making a response, as this is a message the user will see directly. (ie "The answer is ...")
      INSTR

      action = llm(user_request:, history:, instructions:, tools:, json_parser: ACTION_PARSER)

      case action['action']
      when 'RESPONSE'
        previous_step_result = action['raw']
        puts ""
        puts ""
        puts ""
        puts "❇️  #{action['raw']}".green
        return
      when 'TOOL_CALL'
        tool = tools[action['tool_call']['tool_name']]
        args = action['tool_call']['arguments'].map { |arg| [arg['name'].to_sym, arg['value']] }.to_h
        result = tool.run(**args)

        previous_step_result = result
        if verbose
          puts "🧰 Ran #{tool.class.tool_name}(#{args.map { |k, v| "#{k}: #{v}" }.join(', ')}) and got: #{result}".cyan
        else
          puts "🧰 #{tool.class.tool_name}"
        end
      end
    end
  end

  def llm(user_request:, history: '', instructions:, tools: {}, json_parser:)
    base_prompt = <<~PROMPT
      You are a helpful assistant named "aux" that will carefully think through and execute on the user's request.
      You will only be tasked with executing a portion of the request (a sub-task). Anything outside of your particular sub-task is out of scope and should be ignored.

      You have access to a variety of tools that can help you with this task. You do not have to use them all,
      but prefer to use a tool rather than generate a response yourself for all situations where it makes sense.

      Here is the list of tools you have access to and their documentation:
      #{tools.values.map(&:manifest).map(&:to_json).join("\n\n")}
    PROMPT

    prompt = <<~PROMPT
      # General Instructions
      #{base_prompt}

      # The user's request is:
      #{user_request}

      # What we know so far:
      #{history}

      # Your sub-task
      #{instructions}
    PROMPT

    if verbose
      puts "👤 #{prompt}".blue
      puts ""
      puts "🧠 "
    end

    result = ""
    @ollama.generate(model: REASONING_MODEL, stream: true, prompt:) do |response|
      result += response.response
      print response.response.brown if verbose
    end
    puts "\n\n" if verbose

    json_parse.parse(result.gsub(/<think>.*?<\/think>/m, ''), json_parser:, tools:, verbose:)
  end

end

p = Proto.new(verbose: true)
p.test
