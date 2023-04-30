require "listen"

class SoundFileWatcher
  def initialize(folder_path)
    @folder_path = folder_path
  end

  def start
    # first remove all files in the firectory
    Dir.foreach(@folder_path) do |file|
      next if file == "." || file == ".."

      File.delete("#{@folder_path}/#{file}")
    end

    listener = Listen.to(@folder_path, force_polling: true) do |modified, added, removed|
      added.each do |file|
        puts "Playing #{file}"
        system("mpg123 -q '#{file}'")
        File.delete(file)
      end
    end

    listener.start
    sleep
  end
end
