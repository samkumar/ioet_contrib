require "cord"
require "svcd"
shield = require("starter")
sh = require "stormsh"

shield.LED.start()

color = 0
function blinker(color, count)
cord.new(function()
	local i = 0
	while (i < count) do
		shield.LED.on(color)
		cord.await(storm.os.invokeLater, 1*storm.os.SECOND)
		shield.LED.off(color)
		cord.await(storm.os.invokeLater, 1*storm.os.SECOND)
		i = i + 1
	end
end)
   
end

-- start a coroutine that provides a REPL
sh.start()

MyDeviceName = "StarterShield"

cord.new(function()
    cord.await(SVCD.init, MyDeviceName)
    -- or add an echo service that will appear on 15.4 and bluetooth
    -- the service numbers are listed in the manifest:
    -- https://github.com/UCB-IoET/svc/blob/master/manifest.json
    -- Feel free to add new ones by sending pull requests
    SVCD.add_service(0x3002)
    -- Attributes are similarly listed in the manifest
    SVCD.add_attribute(0x3002, 0x4002, function(value)
        local ps = storm.array.fromstr(value)
        local lednum = ps:get(1)
	color = lednum
        local flashcount = ps:get(2)
	print ("got a request to flash led",lednum, " x ", flashcount)
	if (lednum == 0) then
		blinker("red", flashcount)
	elseif (lednum == 1) then
		blinker("red2", flashcount)
	elseif (lednum == 2) then
		blinker("green", flashcount)
	elseif (lednum == 3) then
		blinker("blue", flashcount)
	end
    end)

    storm.os.invokePeriodically(storm.os.SECOND, function()
        SVCD.notify(0x3002, 0x4002, color)
    end)
end)


-- enter the main event loop. This puts the processor to sleep
-- in between events
cord.enter_loop()
