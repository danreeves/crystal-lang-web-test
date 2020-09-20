console.log("booting...")

document.getElementById("login").onsubmit = function (event) {
  event.preventDefault()
  let val = document.getElementById("name").value
  if (val.length > 0) {
	connect(val)
	document.getElementById("login").style="display:none"
	document.getElementById("logged-in").style = "display:block"
  } else {
	alert("you need a name")
  }
}

function connect(username) {
  let ws = new WebSocket("ws://" + document.location.host + "/chat")
  let chat = document.getElementById("chat")
  let users = document.getElementById("users")
  let message = document.getElementById("message")

  window.ws = ws

  ws.onopen = function () {
	document.getElementById("connected").className = "yep"
	document.title = "[connected] chat"
	ws.send(JSON.stringify({
	  type: "logon",
	  from: username
	}))
  }

  ws.onclose = function () {
	document.getElementById("connected").className = ""
	document.title = "chat"
  }

  ws.onmessage = function (event) {
	let data = JSON.parse(event.data)
	console.log(data)
	switch (data.type) {
	  case "message": {
		let msg = document.createElement("DIV")
		msg.className = `message-${data.id} message-${data.from}`
		msg.innerHTML = `${data.from}: ${data.data}`
		chat.appendChild(msg)
		chat.scrollTop = chat.scrollHeight
		break;
	  };
	  case "logon": {
		let user = document.createElement("DIV")
		user.className = `user-${data.id}`
		user.innerHTML = `${data.from}`
		users.appendChild(user)
		break;
	  };
	  case "logoff": {
		let userNodes = document.querySelectorAll(`#users .user-${data.id}`)
		userNodes.forEach(function (node) {
		  if (node.innerHTML == data.from) {
			users.removeChild(node)
		  }
		})
		break;
	  };
	}
  }

  message.onsubmit = function (event) {
	event.preventDefault()
	let text = document.getElementById("input").value
	if (text.length <= 0) return

	document.getElementById("input").value = ""

	if (text == "q") {
	  let data = {
		type: "logoff",
		from: username
	  }
	  ws.send(JSON.stringify(data))
	  ws.close()
	  event.target.value = ""
	  document.getElementById("login").style = "display:block"
	  document.getElementById("logged-in").style = "display:none"
	  chat.innerHTML = ""
	  users.innerHTML = ""
	  document.getElementById("connected").className = ""
	  document.title = "chat"
	  return
	}

	let data = {
	  type: "message",
	  data: text,
	  from: username
	}
	ws.send(JSON.stringify(data))
  }
}
