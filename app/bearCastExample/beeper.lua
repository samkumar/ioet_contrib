require "storm"
require "cord"
require "bearcast"
sh = require "stormsh"

--sh.start()
cord.new(function()
	SVCD.init("bearcast", function() end)
	BEARCAST.init("Beeper", true)
	while true do
		print('beeping')
		BEARCAST.postToClosestDisplay('beep')
		cord.await(storm.os.invokeLater, 1000*storm.os.MILLISECOND)
	end
end)


cord.enter_loop()
