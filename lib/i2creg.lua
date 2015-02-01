
require "cord"
local REG = {}

function REG:new(port, address)
    obj = {port=port, address=address}
    setmetatable(obj, self)	-- associate class methods
    -- Normally you would put this in self, but that would break
    -- cord
    self.__index = self
    return obj
end

function REG:r(key)
    local arr = storm.array.create(1, storm.array.UINT8)
    arr:set(1, key)
    local rv = cord.await(storm.i2c.write,  self.port + self.address,  storm.i2c.START, arr)
    if (rv ~= storm.i2c.OK) then
        print ("ERROR ON I2C: ",rv)
    end
    rv = cord.await(storm.i2c.read,  self.port + self.address,  storm.i2c.RSTART + storm.i2c.STOP, arr)
    if (rv ~= storm.i2c.OK) then
        print ("ERROR ON I2C: ",rv)
    end
    return arr:get(1)
end

function REG:w(key, value)
    local arr = storm.array.create(2, storm.array.UINT8)
    arr:set(1, key)
    arr:set(2, value)
    print ("k,v ", k, v)
    local rv = cord.await(storm.i2c.write,  self.port + self.address,  storm.i2c.START + storm.i2c.STOP, arr)
    if (rv ~= storm.i2c.OK) then
        print ("ERROR ON I2C: ",rv)
    end
end

return REG