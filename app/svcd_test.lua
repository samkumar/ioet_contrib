require "cord"
require "svcd"

cord.new(function ()
	    cord.await(SVCD.init, "unused")
	    SVCD.add_service(0x1337)
	    SVCD.add_attribute(0x1337, 0x1338, function (x)
				  print("received: ", x)
					       end)
	 end)

SVCD.cchanged = function (state)
   if tmrhandle ~= nil then
       storm.os.cancel(tmrhandle)
       tmrhandle = nil
   end
   if state == 1 then
       storm.os.invokePeriodically(1*storm.os.SECOND, function()
				      SVCD.notify(0x1337, 0x1338, string.format("Time: %d", storm.os.now(storm.os.SHIFT_16)))
						      end)
   end
end

--[[function onconnect(state)
   if tmrhandle ~= nil then
       storm.os.cancel(tmrhandle)
       tmrhandle = nil
   end
   if state == 1 then
       storm.os.invokePeriodically(1*storm.os.SECOND, function()
           tmrhandle = storm.bl.notify(char_handle, 
              string.format("Time: %d", storm.os.now(storm.os.SHIFT_16)))
       end)
   end
end


storm.bl.enable("unused", onconnect, function()
   local svc_handle = storm.bl.addservice(0x1337)
   char_handle = storm.bl.addcharacteristic(svc_handle, 0x1338, function(x)
       print ("received: ",x)
   end)
   end) ]]--


cord.enter_loop()

