class UI
  def self.clear_status
    puts " " * 78 + "\r"
  end

  def self.report_status(icon, text)
    clear_status
    puts "#{icon} #{text}...\r"
  end

  def self.report_understood_speech(text)
    clear_status

    if text.empty?
      puts "👂 ⚠️ nieczyt?!!@//one\n"
    else
      puts "👂 #{text.colorize(:blue)}\n"
    end
  end

  def self.report_generated_text(text)
    clear_status

    if text.empty?
      puts "🤖 [no response]\r"
    else
      puts "🤖 #{text.colorize(:green)}\n"
    end
  end
end
