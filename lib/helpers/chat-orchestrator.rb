require "json"
require "net/http"

require "./lib/helpers/conversation"
require "./lib/helpers/interface"
require "./lib/helpers/prompt-generator"

class ChatOrchestrator
  def initialize(audio_input:, speech_to_text:, chat_engine:, text_to_speech:, audio_output:)
    @my_name = "danny"
    @your_name = "emily"

    @drive_path = "/Users/dep/Google Drive/Pipedream/inputs/workflow-triggers"

    @audio_input = audio_input
    @speech_to_text = speech_to_text
    @chat_engine = chat_engine
    @text_to_speech = text_to_speech
    @audio_output = audio_output

    @conversation = Conversation.new
    @prompt_generator = PromptGenerator.new(@conversation)

    raise "No audio input" unless @audio_input
    raise "No speech to text" unless @speech_to_text
    raise "No chat engine" unless @chat_engine
    raise "No text to speech" unless @text_to_speech
  end

  def fire_event(url)
    uri = URI(url)
    req = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")

    req.body = {
      "from_emily": true,
    }.to_json

    Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == "https") do |http|
      http.request(req)
    end
  end

  def start!
    UI.report_status("🎙️", "listening")

    # let's loop through audio chunks we've detected worth considering as sentences
    @audio_input.start do |audio_buffer|
      UI.report_status("🤫", "whisper processing")

      # use speech to text engine to convert audio buffer we've received to text
      speech_text = @speech_to_text.process(audio_buffer)

      if speech_text.nil? || speech_text.empty?
        # we might have not understood what the user said, let's invite them to try again
        # ask_to_repeat
      else
        # give feedback by displaying what we've understood
        UI.report_understood_speech(speech_text)

        # let's remember what the user said for future context
        @conversation.remember_my_statement(speech_text)

        process_common_requests(speech_text)

        if speech_text.length > 10 && speech_text.downcase.include?(@your_name)
          say(one_moment_string)
          response_text = @chat_engine.ask(@prompt_generator.generate)
        else
          response_text = ""
        end

        if !response_text
          response_text = ""
        end

        if response_text.length > 0
          # we've generated something, let's just say it
          say(response_text)

          # and remember for future context as well
          @conversation.remember_generated_statement(response_text)
        end
      end

      UI.report_status("🎙️", "listening")
    end
  end

  def prompt_for_text_input
    loop do
      print "Please enter your text input (type 'exit' to quit): "
      user_input = gets.chomp

      break if user_input.downcase == "exit"

      process_text_input(user_input)
    end
  end

  def process_text_input(input_text)
    # let's remember what the user said for future context
    @conversation.remember_my_statement(input_text)

    process_common_requests(input_text)

    response_text = @chat_engine.ask(@prompt_generator.generate)

    if !response_text
      response_text = ""
    end

    if response_text.length > 0
      # we've generated something, let's just say it
      say(response_text)

      # and remember for future context as well
      @conversation.remember_generated_statement(response_text)
    end
  end

  def process_common_requests(input_text)
    if input_text.downcase.include?("weather") || input_text.downcase.include?("forecast")
      say("I'll be right back with the weather.")
      fire_event("https://eose1ey7rdg1rpm.m.pipedream.net")
    elsif input_text.downcase.include?("stocks") || input_text.downcase.include?("stock market")
      say("Let me check the stock market and get back to you.")
      fire_event("https://eons1sdz6qhiy1x.m.pipedream.net")
    elsif input_text.downcase.include?("todoist") || input_text.downcase.include?("task list") || input_text.downcase.include?("to-do") || input_text.downcase.include?("todo")
      say("Lets get that task added to todoist for you. Give me a minute.")
      # make_and_kill_trigger_file("todoist", input_text)
    end
  end

  def one_moment_string
    one_moment_strings = [
      "Hmm, give me a minute to look that up. I'll be right back with an answer",
      "Just a moment. I'll check into that now. Thanks for your patience.",
      "Hold on... Let me look that up. I'll be right back...",
      "Wait a second #{@my_name}. I have to look that up... Rome wasn't built in a day.",
      "Wait a moment #{@my_name}... I have to process this. Perfection takes time.",
    ]
    one_moment_strings.sample
  end

  # if report_generated_text is set to false, then we won't remember we said that
  # and also won't display in the UI explicitly that we're generating that audio
  # useful for errors, asking to repeat and some such
  def say(text, report_generated_text = true)
    UI.report_status("🦜", "converting to audio") if report_generated_text

    speech_audio = @text_to_speech.synthesize(text)

    UI.report_generated_text(text) if report_generated_text

    @audio_output.play(speech_audio)
  end

  private

  def ask_to_repeat(text = "Say that again, please?")
    say(text, false)
  end
end
