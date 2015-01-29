require("storm") -- libraries for interfacing with the board and kernel
require("cord") -- scheduler / fiber library

function deltaMaker()
   now = storm.os.now(storm.os.SHIFT_0)
   return function()
      return storm.os.now(storm.os.SHIFT_0) - now
      end
end

t = storm.os.invokePeriodically(4*storm.os.SECOND, function()
			       print(string.format("It is now %0x", 
						   (storm.os.now(storm.os.SHIFT_0))))
					       end)

