require_relative "lib/sound_file_watcher"

folder_path = ARGV[0] || "/Users/dep/Google Drive/Pipedream/outputs/elevenlabs-results/"

puts "Watching folder: #{folder_path}"
watcher = SoundFileWatcher.new(folder_path)
watcher.start
