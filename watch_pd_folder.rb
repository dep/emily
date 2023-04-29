require_relative "lib/sound_file_watcher"

folder_path = ARGV[0] || "/Users/dep/Google Drive/Miscellaneous/Pipedream/"

puts "Watching folder: #{folder_path}"
watcher = SoundFileWatcher.new(folder_path)
watcher.start
