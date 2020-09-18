require "file"
require "process"

def watch(glob, command, args)
  files = Dir.glob(glob)
  timestamps = {} of String => Time

  stdout = IO::Memory.new
  process = Process.new(command, args, output: stdout)

  # Collect the list of current files watched
  files.each do |file|
    timestamps[file] = File.info(file).modification_time
  end




  loop do
    # If there is stdout then print it and clear the buffer
    output = stdout.to_s
    if output.size > 0
      puts output
      stdout.clear
    end

    files.each do |file|
      time = File.info(file).modification_time
      if time != timestamps[file]
        puts "#{file} modified"
        process.terminate
        timestamps[file] = time
      end
    end

    sleep 1
  end
end

watch "./src/**/*.cr", "crystal", ["run", "src/main.cr"]
