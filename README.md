<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>Stomp Websockets</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
	<meta http-equiv="X-UA-Compatible" content="IE=edge">
    <script src="stomp.js" type="text/javascript"></script>
    <script src="jquery.min.js" type="text/javascript"></script>

   <script>//<![CDATA[
   <!--function setCookie(name,value){document.cookie = name+'='+encodeURIComponent(value);}-->
   function getCookie(name){
	 var  search = name+"=";
	 if(document.cookie.length>0){
		offset = document.cookie.indexOf(search);  
                 if(offset != -1)  
                 {  
                     offset += search.length  
                     end = document.cookie.indexOf(";", offset)  
                     if(end == -1) end = document.cookie.length  
                     return unescape(document.cookie.substring(offset, end))  
                 }  
                 else return ""; 
	 }
   }
   function getContextPath(){
	var pathname = document.location.pathname;
	var index = pathname.lastIndexOf("/");
	var subpath = pathname.substr(0,index);
	var index2 = subpath.lastIndexOf("/");
	var result = subpath.substr(index2+1,subpath.length);
	return result;
   }   
    $(document).ready(function() {
			var login =getContextPath();
		 var passcode=getCookie("INTSESSION");
		 document.getElementById("connect_login").value=login;
		 document.getElementById("connect_passcode").value=passcode;
      if(window.WebSocket) {
        var client, destination,received;
        $('#connect_form').submit(function() {
          var url = $("#connect_url").val();
          var login = $("#connect_login").val();
          var passcode = $("#connect_passcode").val();
          destination = $("#destination").val();
		  received = $("#received").val();
          
		  client = Stomp.client(url);

          // this allows to display debug logs directly on the web page
          client.debug = function(str) {
            $("#debug").append(str + "\n");
          };
          
          // the client is notified when it is connected to the server.
          client.connect(login, passcode, function(frame) {
            client.debug("connected to Stomp");
            $('#connect').fadeOut({ duration: 'fast' });
            $('#connected').fadeIn();
			client.subscribe(received, function(message) {
              $("#ws").append("<li>"+"received:" + message.body + "</li>");
            });
          });
          return false;
        });
  
        $('#disconnect').click(function() {
          client.disconnect(function() {
            $('#connected').fadeOut({ duration: 'fast' });
            $('#connect').fadeIn();
            $("#messages").html("")
          });
          return false;
        });
   
        $('#send_form').submit(function() {
          var text = $('#text').val();
          if (text) {
            client.send(destination, {}, text);
			$("#ws").append("<li>"+"send:" + text + "</li>");
            $('#text').val("");
          }
          return false;
        });
      } else {
        $("#connect").html("\
            <h1>Get a new Web Browser!</h1>\
            <p>\
            Your browser does not support WebSockets. This example will not work properly.<br>\
            Please use a Web Browser with WebSockets support (WebKit or Google Chrome).\
            </p>\
        ");
      }
    });
    //]]></script>
  </head>
  <body>
  <div id="connect">
    <h1>Stomp Websockets</h1>
    <div>
		
         <form class="form-horizontal" id='connect_form'>
              <fieldset>
                <div class="control-group">
                  <label>WebSocket URL</label>
                  <div class="controls">
                    <input id='connect_url' value='' type="text">
                  </div>
                </div>
                <div class="control-group">
                  <label>User</label>
                  <div class="controls">
                    <input id='connect_login' placeholder="User Login" value="admin" type="text">
                  </div>
                </div>
                <div class="control-group">
                  <label>Password</label>
                  <div class="controls">
                    <input id='connect_passcode' placeholder="User Password" value="password" type="password">
                  </div>
                </div>
                <div class="control-group">
                  <label>Destination</label>
                  <div class="controls">
                    <input id='destination' placeholder="Destination" value="/topic/dest1" type="text">
                  </div>
                </div>
				<div class="control-group">
                  <label>Received from</label>
                  <div class="controls">
                    <input id='received' placeholder="Received" value="/topic/dest2" type="text">
                  </div>
                </div>
                <div class="form-actions">
                  <button id='connect_submit' type="submit" class="btn btn-large btn-primary">Connect</button>
                </div>
              </fieldset>
            </form>   	       
    </div>
	</div>
	 <div id="connected" style="display:none">
             <ul id='ws' style="font-family: 'Courier New', Courier, monospace;"></ul>
            <form class="well form-search" id='send_form'>
              <button class="btn" type="button" id='disconnect'>Disconnect</button>
              <input class="input-medium" id='text' placeholder="Type your message here" class="span6"/>
              <button class="btn" type="submit">Send</button>
            </form>
     </div>
	
	 <div class="span4">
          <pre id="debug"></pre>
    </div>
	 
  </body>
</html>
