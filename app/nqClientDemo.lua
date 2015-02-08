-- This is meant to be run on the client Firestorm. The starter shield is required.

NQC = require "nqclient"
LED = require "led"
BUTTON = require "button"

red = LED:new("D4")
grn = LED:new("D3")
blu = LED:new("D2")

nqcl = NQC:new(50001)

topress = BUTTON:new("D9")

count = 1

topress:whenever("RISING", function ()
    print("Sending...")
    blu:flash()
    nqcl:sendMessage({["message"] = "hello #" .. count}, "ff02::1", 50004, function (payload, address, port)
        red:flash()
        print("Successfully sent! Response received: " .. payload.message)
    end, function ()
        print("Message could not be sent")
    end, function ()
        grn:flash()
    end)
    count = count + 1
end)

sh = require "stormsh"
sh.start()

cord.enter_loop()
