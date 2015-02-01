--[[
   echo client as server
   currently set up so you should start one or another functionality at the
   stormshell

--]]

require "cord" -- scheduler / fiber library
LED = require("led")
brd = LED:new("GP0")

print("echo test")
brd:flash(4)
sock = nil

ipaddr = storm.os.getipaddr()
ipaddrs = string.format("%04x%04x:%04x%04x:%04x%04x:%04x%04x::%04x%04x:%04x%04x:%04x%04x:%04x%04x",
			ipaddr[0],
			ipaddr[1],ipaddr[2],ipaddr[3],ipaddr[4],
			ipaddr[5],ipaddr[6],ipaddr[7],ipaddr[8],	
			ipaddr[9],ipaddr[10],ipaddr[11],ipaddr[12],
			ipaddr[13],ipaddr[14],ipaddr[15])

print("ip addr", ipaddrs)
print("node id", storm.os.nodeid())

-- create echo server as handler
server = function()
   sock = storm.net.udpsocket(7, 
			      function(payload, from, port)
				 brd:flash(1)
				 print (string.format("from %s port %d: %s",from,port,payload))
-- client should be able to listen on the port that this arrives on
-- print(storm.net.sendto(sock, payload, from, port))
				 print(storm.net.sendto(sock, payload, from, 7))
				 brd:flash(1)
			      end)
end

-- client side
button = require("button")
btn = button:new("D9")		-- button 1 on starter shield

client = function()
   blu = LED:new("D2")		-- LEDS on starter shield
   grn = LED:new("D3")
   red = LED:new("D4")
   -- replace server handler with response handler
   sock = storm.net.udpsocket(7, 
			      function(payload, from, port)
				 red:flash(3)
				 print (string.format("echo from %s port %d: %s",from,port,payload))
			      end)
   -- send echo on each button press
   count = 0
--   btn:whenever("FALLING",
   storm.os.invokePeriodically(5*storm.os.SECOND,
			       function() 
				  blu:flash(1)
				  local msg = string.format("0x%04x says count=%d", storm.os.nodeid(), count)
				  print(msg)
				  -- end upd echo to link local all nodes multicast
				  storm.net.sendto(sock, msg, "ff02::1", 7) 
				  count = count + 1
				  grn:flash(1)
			       end)
end


--btn:when("CHANGE",client)

-- enable a shell
sh = require "stormsh"
sh.start()
cord.enter_loop() -- start event/sleep loop
