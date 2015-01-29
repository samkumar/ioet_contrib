
require "cord" -- scheduler / fiber library

storm.io.set_mode(storm.io.OUTPUT, storm.io.GP0)

local flash=function(times)
   cord.new(function()
	       times = times or 1
	       local i
	       for i = 1,times do 
		  if i ~= 1 then 
		     cord.await(storm.os.invokeLater,50*storm.os.MILLISECOND)
		  end
		  storm.io.set(1,storm.io.GP0) 
		  cord.await(storm.os.invokeLater,10*storm.os.MILLISECOND)
		  storm.io.set(0,storm.io.GP0) 
	       end
	    end)
end

local sock = storm.net.udpsocket(100, function(payload, from, port)
    print (string.format("Got a message from %s port %d",from,port))
    flash(1)
    print ("Payload: ", payload)
end)

local count = 0
storm.os.invokePeriodically(5*storm.os.SECOND, function()
			       local msg = string.format("0x%04x says count=%d", storm.os.nodeid(), count)
			       print(msg)
			       storm.net.sendto(sock, msg, "ff02::1", 100)
			       count = count + 1
			       flash(2)
					       end
)

cord.enter_loop() -- start event/sleep loop
