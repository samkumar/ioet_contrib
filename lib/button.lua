require("storm") -- libraries for interfacing with the board and kernel
require("cord") -- scheduler / fiber library

----------------------------------------------
-- button class
--   basic button functions associated with a shield pin
--   assume cord.enter_loop() is active, as per stormsh
----------------------------------------------
local Button = {}

function Button:new(bpin)
   assert(bpin and storm.io[bpin], "invalid pin spec")
   obj = {pin = bpin}		-- initialize the new object
   setmetatable(obj, self)	-- associate class methods
   self.__index = self
   storm.io.set_mode(storm.io.INPUT, storm.io[bpin])
   storm.io.set_pull(storm.io.PULL_UP, storm.io[bpin])
   return obj
end

function Button:pressed()
   return storm.io.get(storm.io[self.pin]) 
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
function Button:whenever (transition, action)
   assert(storm.io[transition],"Bad transition")
   -- register call back to fire when button is pressed
   storm.io.watch_all(storm.io[transition], storm.io[self.pin], action)
end

function Button:when (transition, action)
   -- register call back to fire when button is pressed
   storm.io.watch_single(storm.io[transition], storm.io[self.pin], action)
end

function Button:wait()
-- Wait on a button press
--   suspend execution of the filament
--   resume and return when transition occurs
   cord.await(storm.io.watch_single, storm.io.FALLING, storm.io[self.pin])
end

return Button

