----------------------------------------------
-- Basic Shield Module
--
----------------------------------------------

require("storm") -- libraries for interfacing with the board and kernel
require("cord") -- scheduler / fiber library

LED = {pin = "D2"}
Button = {pin = "D3"}
Buzz = {pin = "D6"}

----------------------------------------------
-- LED module
-- provide basic LED functions
----------------------------------------------
LED.start = function()
-- configure LED pins for output
   storm.io.set_mode(storm.io.OUTPUT, storm.io[LED.pin])
end

LED.stop = function()
-- configure pins to a low power state
end

-- LED color functions
-- These should rarely be used as an active LED burns a lot of power
LED.on = function()
   storm.io.set(1,storm.io[LED.pin])
end

LED.off = function(color)
   storm.io.set(0,storm.io[LED.pin])
end

-- Flash an LED pin for a period of time
--    unspecified duration is default of 10 ms
--    this is dull for green, but bright for read and blue
--    assumes cord.enter_loop() is in effect to schedule filaments
LED.flash=function(duration)
   duration = duration or 10
   storm.io.set(1,storm.io[LED.pin])
   storm.os.invokeLater(duration*storm.os.MILLISECOND,
			function() 
			   storm.io.set(0,storm.io[LED.pin]) 
			end)
end

----------------------------------------------
-- Buzz module
-- provide basic buzzer functions
----------------------------------------------

Buzz.go = function(delay)
   delay = delay or 0
   local pin =  Buzz.pin
   -- configure buzzer pin for output
   storm.io.set_mode(storm.io.OUTPUT, storm.io[pin])
   Buzz.run = true
   -- create buzzer filament and run till stopped externally
   cord.new(function()
	       while Buzz.run do
		  storm.io.set(1,storm.io[pin])
		  storm.io.set(0,storm.io[pin])	       
		  if (delay == 0) then cord.yield()
		  else cord.await(storm.os.invokeLater, 
				  delay*storm.os.MILLISECOND)
		  end
	       end
	    end)
end

Buzz.stop = function()
   Buzz.run = false		-- stop Buzz.go partner
end

----------------------------------------------
-- Button module
-- provide basic button functions
----------------------------------------------
Button.start = function()
   -- set buttons as inputs
   storm.io.set_mode(storm.io.INPUT, storm.io[Button.pin])
   -- enable internal resistor pullups (none on board)
   storm.io.set_pull(storm.io.PULL_UP, storm.io[Button.pin])
end


-- Get the current state of the button
-- can be used when poling buttons
Button.pressed = function(button) 
   return storm.io.get(storm.io[Button.pin]) 
end

-------------------
-- Button events
-- each registers a call back on a particular transition of a button
-- valid transitions are:
--   FALLING - when a button is pressed
--   RISING - when it is released
--   CHANGE - either case
-- Only one transition can be in effect for a button
-- must be used with cord.enter_loop
-- none of these are debounced.
-------------------
Button.whenever = function(transition, action)
   -- register call back to fire when button is pressed
   local pin = Button.pin
   storm.io.watch_all(storm.io[transition], storm.io[pin], action)
end

Button.when = function(transition, action)
   -- register call back to fire when button is pressed
   local pin = Button.pin
   storm.io.watch_single(storm.io[transition], storm.io[pin], action)
end

Button.wait = function(button)
-- Wait on a button press
--   suspend execution of the filament
--   resume and return when transition occurs
   local pin = Button.pin
   cord.await(storm.io.watch_single,
	      storm.io.FALLING, 
	      storm.io[pin])
end



function testLED()
   LED.start()
   LED.flash(50)
end

function testbutton(pin)
   storm.io.set_mode(storm.io.INPUT, storm.io[pin])
   storm.io.set_pull(storm.io.PULL_UP, storm.io[pin])
   storm.io.watch_all(storm.io.FALLING, storm.io[pin], 
		      function () 
			 print("button", storm.io.get(storm.io[pin]))
		      end)
end

function dumbtestbutton(pin) 
   storm.io.set_mode(storm.io.INPUT, storm.io[pin])
   storm.io.set_pull(storm.io.PULL_UP, storm.io[pin])
   while (true) do
      print("button", storm.io.get(storm.io[pin]))
   end
end

function testBUZZ(delay)
   Buzz.go(delay)
   storm.os.invokeLater(storm.os.SECOND, Buzz.stop)
end

sh = require "stormsh"
-- start a coroutine that provides a REPL
sh.start()

-- enter the main event loop. This puts the processor to sleep
-- in between events
cord.enter_loop()





