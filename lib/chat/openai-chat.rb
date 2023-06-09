# load .env
require "dotenv/load"

require "json"
require "openai"
require "colorize"

OpenAI.configure do |config|
  config.access_token = ENV["OPENAI_API_KEY"]
end

class OpenAIChat
  def initialize(model: "gpt-3.5-turbo", temperature: 0.8, max_tokens: 250, debug: false)
    @client = OpenAI::Client.new
    @model = model
    @temperature = temperature
    @max_tokens = max_tokens
    @debug = debug
  end

  def ask(text)
    debug(">>>>> Asking OpenAI chat. Model #{@model}. Temperature: #{@temperature}. Max tokens: #{@max_tokens}:\n#{text}")

    response = @client.chat(
      parameters: {
        model: @model,
        messages: [{ role: "user", content: text }],
        temperature: @temperature,
        max_tokens: @max_tokens,
      },
    )

    response.dig("choices", 0, "message", "content")
  end

  private

  def debug(text)
    puts text.colorize(:magenta) if @debug
  end
end
