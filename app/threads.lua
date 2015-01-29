require("storm") -- libraries for interfacing with the board and kernel
require("cord") -- scheduler / fiber library
print ("CORD  test ")

sh = require "stormsh"

thread1 = function() 
   local i
   for i=1,10 do
      print("thread 1", 1)
      cord.yield()
   end
end

thread2 = function() 
   local i
   for i=1,10 do
      print("thread 2", 1)
      cord.yield()
   end
end

function startThreads()
   cord.new(thread1)
   cord.new(thread2)
end

function threads(numThreads, loops)
   local i
   for i = 1, numThreads do
      cord.new(function()
		  local j
		  for j = 1,loops do
		     print("Thread",i,j)
		     cord.yield()
		  end
	       end)
   end
end

function sthreads(numThreads, loops)
   local i
   for i = 1, numThreads do
      cord.new(function()
		  local j
		  for j = 1,loops do
		     print("Thread",i,j)
		     cord.await(storm.os.invokeLater, 1*storm.os.SECOND)
		  end
	       end)
   end
end

-- start a coroutine that provides a REPL
sh.start()

-- enter the main event loop. This puts the processor to sleep
-- in between events
cord.enter_loop()




