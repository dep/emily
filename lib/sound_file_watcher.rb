require "listen"

class SoundFileWatcher
  def initialize(folder_path)
    @folder_path = folder_path
  end

  def start
    listener = Listen.to(@folder_path) do |modified, added, removed|
      added.each do |file|
        system("mpg123 -q '#{file}'")
        File.delete(file)
      end
    end

    listener.start
    sleep
  end
end
