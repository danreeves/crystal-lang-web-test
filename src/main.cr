require "uuid"
require "json"
require "kemal"

get "/" do
  " <!-- welcome to the internet -->
    <title>chat</title>
    <link rel=stylesheet href=/css/style.css />
      <h1><div id=connected></div>chat</h1>
      <form id=login>
        <label for=name>
          Name
        </label>
        <input type=text id=name />
        <button type=submit id=connect>log&nbsp;on</button>
      </form>
      <div id=logged-in>
        <div id=window>
          <div id=chat></div>
          <div id=users></div>
        </div>
        <form id=message>
        <label for=input>
          Message
        </label>
        <input type=text id=input />
        <button type=submit id=send>send</button>
        </form>
      </div>
    <script src=/js/main.js></script>
  "
end

sockets = [] of HTTP::WebSocket
names = {} of HTTP::WebSocket => String
ids = {} of HTTP::WebSocket => String

ws "/chat" do |socket|
  socket.send(%({"type": "message", "from": "system", "data": "you're online..."}))
  sockets << socket

  socket.on_message do |message|
    data = Hash(String, String).from_json(message)
    case data["type"]
    when "logon"
      name = data["from"]
      id = UUID.random.hexstring

      names.each do |n|
        # Tell the user that logged on about everyone else
        socket.send(%({
          "type": "logon",
          "from": "#{n[1]}",
          "id": "#{ids[n[0]]}"
        }))

        # Tell everyone else they logged in
        n[0].send(%({
          "type": "message",
          "from": "system",
          "data": "#{name} joined"
        }))
      end

      ids[socket] = id
      names[socket] = name

    end

    if !names[socket].blank?
      sockets.each do |s|
        data["id"] = ids[socket]
        s.send data.to_json
      end
    end
  end

  socket.on_close do
    sockets.each do |s|
      s.send(%({
        "type": "logoff",
        "name": "#{names[socket]}"
      }))
    end
    sockets.delete(socket)
    names.delete(socket)
    ids.delete(socket)
    socket.close(HTTP::WebSocket::CloseCode::NormalClosure)
  end
end

Kemal.run
