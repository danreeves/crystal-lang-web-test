require "kemal"

get "/" do
  "<h1>hello, planet!</h1>"
end

Kemal.run
