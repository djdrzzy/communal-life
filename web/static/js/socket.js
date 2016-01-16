// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "web/static/js/app.js".

// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in "lib/my_app/endpoint.ex":
import {Socket} from "deps/phoenix/web/static/js/phoenix"

let socket = new Socket("/socket", {params: {token: window.userToken}})

// When you connect, you'll often need to authenticate the client.
// For example, imagine you have an authentication plug, `MyAuth`,
// which authenticates the session and assigns a `:current_user`.
// If the current user exists you can assign the user's token in
// the connection for use in the layout.
//
// In your "web/router.ex":
//
//     pipeline :browser do
//       ...
//       plug MyAuth
//       plug :put_user_token
//     end
//
//     defp put_user_token(conn, _) do
//       if current_user = conn.assigns[:current_user] do
//         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
//         assign(conn, :user_token, token)
//       else
//         conn
//       end
//     end
//
// Now you need to pass this token to JavaScript. You can do so
// inside a script tag in "web/templates/layout/app.html.eex":
//
//     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
//
// You will need to verify the user token in the "connect/2" function
// in "web/channels/user_socket.ex":
//
//     def connect(%{"token" => token}, socket) do
//       # max_age: 1209600 is equivalent to two weeks in seconds
//       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600) do
//         {:ok, user_id} ->
//           {:ok, assign(socket, :user, user_id)}
//         {:error, reason} ->
//           :error
//       end
//     end
//
// Finally, pass the token on connect as below. Or remove it
// from connect if you don't care about authentication.

// Super dirty code below I know... but this is just a little janky side-project

socket.connect();

// Now that you are connected, you can join channels with a topic:
let channel = socket.channel("update:grid", {});
let stepCounter = $('#stepCounter');
let debug = $('#debug');
let peopleConnected = $('#peopleConnected');
let highwater = $('#highwater');

let mouseIsClicked = false;

$('#golCanvas').mouseout(function(event) {
    mouseIsClicked = false;
});

$('#golCanvas').mousedown(function(event) {
    mouseIsClicked = true;
    handleCellAddition(event);
});

$('#golCanvas').mouseup(function(event) {
    mouseIsClicked = false;
});

$('#golCanvas').mousemove(function(event) {
    handleCellAddition(event);
});

function handleCellAddition(event) {
    if (mouseIsClicked) {
	let xPosition = Math.ceil((event.offsetX / event.currentTarget.offsetWidth) * event.currentTarget.width) - 1;

	let yPosition = Math.ceil((event.offsetY / event.currentTarget.offsetHeight) * event.currentTarget.height) - 1;

	updateCanvasAtPosition(xPosition, yPosition, 100, 100, 100);

	channel.push("user_update", {x: xPosition, y: yPosition});
    }
}

function updateCanvasAtPosition(x, y, r, g, b) {
    let context = golCanvas.getContext('2d');

    let imageData = context.getImageData(0, 0, 64, 64);

    let i = ((y * 64) + x) * 4;

    imageData.data[i + 0] = r;
    imageData.data[i + 1] = g;
    imageData.data[i + 2] = b;
    imageData.data[i + 3] = 255;

    context.putImageData(imageData, 0, 0);
}

channel.on("new_update", payload => {
    stepCounter.text("Step: " + payload.step);
    peopleConnected.text("People Connected: " + payload.people_connected);
    highwater.text("Highwater Mark For People Connected: " + payload.highwater);
    let context = golCanvas.getContext('2d');

    let imageData = context.createImageData(payload.width, payload.height);

    let byteCharacters = atob(payload.game_state);

    let byteNumbers = new Array(byteCharacters.length);
    for (let i = 0; i < byteCharacters.length; i++) {
	byteNumbers[i] = byteCharacters.charCodeAt(i);
    }
    
    while(byteNumbers.length < 512) {
	byteNumbers.unshift(0);
    }

    let byteArray = new Uint8Array(byteNumbers);
    
    for (let i = 0; i < imageData.data.length; i = i + 4) {
	
	let byteIndex = Math.floor((i / 4) / 8);
	let byteToCheck = byteArray[byteIndex];
	
	let insideByteIndex = (i / 4) % 8;
	let insideByteOffset = 0x80 >> insideByteIndex;

	let offOrOn = byteToCheck & insideByteOffset;
	
	imageData.data[i + 0] = offOrOn == 0 ? 255 : 0;
	imageData.data[i + 1] = 0;
	imageData.data[i + 2] = 0;
	imageData.data[i + 3] = 255;
    }

    context.putImageData(imageData, 0, 0);
});

channel.join()
    .receive("ok", resp => { console.log("Joined successfully", resp) })
    .receive("error", resp => { console.log("Unable to join", resp) });



export default socket
