require "./lib/helpers/conversation"
require "./lib/helpers/interface"
require "./lib/helpers/prompt-generator"

class ChatOrchestrator
  def initialize(audio_input:, speech_to_text:, chat_engine:, text_to_speech:, audio_output:)
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

  def make_and_kill_trigger_file(trigger_file, speech_text)
    file = "#{@drive_path}/#{trigger_file}/#{trigger_file}.txt"

    # Add contents of speech_text into a file
    File.open(file, "w") do |file|
      file.puts(speech_text)
    end

    # After 60 seconds, remove the file using a separate thread
    Thread.new do
      sleep(60)
      File.delete(file)
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

        # let's generate a response from chat engine
        UI.report_status("🧠", "generating response text")

        # build list of possible 'one moment' strings
        one_moment_strings = [
          "Hmm, give me a minute to look that up. I'll be right back with an answer",
          "Just a moment. I'll check into that now. Thanks for your patience.",
          "Hold on... Let me look that up. I'll be right back...",
          "Wait a second Danny. I have to look that up... Rome wasn't built in a day.",
          "Wait a moment Danny... I have to process this. Perfection takes time.",
        ]
        one_moment_string = one_moment_strings.sample

        if speech_text.downcase.include?("weather") || speech_text.downcase.include?("forecast")
          say("I'll be right back with the weather.")
          make_and_kill_trigger_file("weather", speech_text)
        elsif speech_text.downcase.include?("stocks") || speech_text.downcase.include?("stock market")
          say("Let me check the stock market and get back to you.")
          make_and_kill_trigger_file("stocks", speech_text)
        elsif speech_text.downcase.include?("todoist") || speech_text.downcase.include?("task list") || speech_text.downcase.include?("to-do") || speech_text.downcase.include?("todo")
          say("Lets get that task added to todoist for you. Give me a minute.")
          make_and_kill_trigger_file("todoist", speech_text)
        end

        if speech_text.length > 10 && speech_text.downcase.include?("emily")
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
