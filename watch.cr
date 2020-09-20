require "watch"
Watch.watch "./src/**/*.cr", "crystal run src/main.cr", opts: [:on_start]
Watch.run
