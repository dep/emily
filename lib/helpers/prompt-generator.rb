class PromptGenerator
  def initialize(conversation)
    @conversation = conversation
  end

  def prefix
    "Referring to me as the nickname 'Danny', reply to this question. When in doubt, expand on the first obvious topic without prompting for clarification. Respond in English."
  end

  def generate
    prompt = prefix + "\n" + @conversation.prepare_context_prompt + "\n\n"

    # puts "Prompt generated:\n======================#{prompt}\n======================\n\n"

    prompt
  end
end
