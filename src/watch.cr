require "file"
require "process"
require "colorize"

def children_of(pid : Int64)
  pids = [pid] of Int64
  output = `ps ao pid,ppid`.split('\n')
  output.delete_at(0)
  output = output.map do |line|
    line.split(' ').map do |col|
      col.strip
    end
      .reject do |col|
        col.blank?
      end
  end
    .reject do |row|
      row.empty?
    end
    .each do |row|
      if pids.includes?(row[1].to_i64)
        pids << row[0].to_i64
      end
    end

  return pids
end

def watch(glob, full_command, opts = [] of ElementType)
  spawn do
    files = Dir.glob(glob)
    timestamps = {} of String => Time
    command_parts = full_command.split(" ")
    command = command_parts[0]
    args = command_parts[1, full_command.size]

    stdout = IO::Memory.new
    process = nil
    if opts.includes?(:on_start)
      puts "> running \"#{command} #{args.join(" ")}\"".colorize(:green)
      process = Process.new(command, args, output: stdout)
    end

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
          if opts.includes?(:log_changes)
            puts ">> #{file} modified".colorize(:yellow)
          end
          if process && !process.terminated?
            children_of(process.pid).each do |pid|
              Process.signal(Signal::INT, pid)
            end
          end
          puts "> running \"#{command} #{args.join(" ")}\"".colorize(:green)
          process = Process.new(command, args, output: stdout)
          timestamps[file] = time
        end
      end

      sleep 0.1
    end
  end
end

watch "./src/**/main.cr", "crystal run src/main.cr", [:on_start]
watch "./src/**/*.cr", "echo \"nice\"", [:log_changes, :on_start]
sleep
