NQC = require "nqclient"
LED = require "led"
BUTTON = require "button"

red = LED:new("D4")
grn = LED:new("D3")
blu = LED:new("D2")

nqcl = NQC:new(50001)

topress = BUTTON:new("D9")

topress:whenever("RISING", function ()
    print("Sending...")
    blu:flash()
    nqcl:sendMessage({["message"] = "hello!"}, "ff02::1", 50004, function (payload, address, port)
        red:flash()
        print("Successfully sent! Response received: " .. payload.message)
    end, function ()
        print("Message could not be sent")
    end, function ()
        grn:flash()
    end)
end)

sh = require "stormsh"
sh.start()

cord.enter_loop()
