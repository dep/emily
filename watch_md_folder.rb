require "listen"
require "http"
require "rest-client"

class MarkdownFileWatcher
  def initialize(folder_path)
    @folder_path = folder_path
    @base_url = "https://api.elevenlabs.io/v1"
    @default_voice_id = ENV["ELEVEN_LABS_DEFAULT_VOICE_ID"]
    @api_key = ENV["ELEVEN_LABS_API_KEY"]
  end

  def read_file(file)
    File.read(file)
  end

  def synthesize(text, voice_id = @default_voice_id)
    url = "#{@base_url}/text-to-speech/#{voice_id}"

    data = {
      "text": text,
      "voice_settings": {
        "stability": 0,
        "similarity_boost": 0,
      },
    }

    begin
      response = RestClient.post url, data.to_json, { "xi-api-key" => @api_key, content_type: :json }

      # Write the response body to a temporary file
      temp_file = Tempfile.new(["audio", ".mp3"])
      temp_file.write(response.body)
      temp_file.close

      # Play the audio using the temporary file
      system("mpg123 -q '#{temp_file.path}'")

      # Close and delete the temporary file
      temp_file.unlink
    rescue Exception => e
      puts "ElevenLabs: Error: #{e.message}"
      ap e
    end
  end

  def start
    listener = Listen.to(@folder_path) do |_, added, _|
      added.each do |file|
        next unless File.extname(file) == ".md"

        content = read_file(file)
        synthesize(content)
      end
    end

    listener.start
    sleep
  end
end

folder_path = ARGV[0] || "/Users/dep/Google Drive/Obsidian/Brain 2.0/GPT Summaries/"
puts "Watching folder: #{folder_path}"
watcher = MarkdownFileWatcher.new(folder_path)
watcher.start
