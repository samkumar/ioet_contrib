require("storm") -- libraries for interfacing with the board and kernel
require("cord") -- scheduler / fiber library
print ("BLE  test ")

function onconnect(state)
   print("BLE Connect", state)
   if state == 1 then		-- connected
      storm.bl.notify(char_handle, "connected");
   end
end

function ready()
   print("BLE Ready")
   -- add a service
   svc_handle = storm.bl.addservice(0x1337)
   print("BLE svc handle:", svc_handle)
   -- add a characteristic
   char_handle = storm.bl.addcharacteristic(svc_handle, 0x1338, 
					    function(x)
					       print ("BLE 0x1338 rcv: ",x)
					    end)
   print("BLE char handle:", char_handle)
end

storm.bl.enable("unused", onconnect, ready)

sh = require "stormsh"
-- start a coroutine that provides a REPL
sh.start()

-- enter the main event loop. This puts the processor to sleep
-- in between events
cord.enter_loop()
