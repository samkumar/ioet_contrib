require "cord"
local REG = {}

--[[

The REG register type represents the registers associated with at port PORT
(storm.i2c.INT or storm.i2c.EXT) and address ADDRESS.

It provides an abstraction for reading and writing to registers.

]]--

-- Create a new I2C register binding
function REG:new(port, address)
    obj = {port=port, address=address}
    setmetatable(obj, self)
    self.__index = self
    return obj
end

-- Read a given register address
function REG:r(reg)
    -- create array with address
    local arr = storm.array.create(1, storm.array.UINT8)
    arr:set(1, reg)
    -- write address
    local rv1 = cord.await(storm.i2c.write, self.port + self.address, storm.i2c.START, arr)
    if rv1 ~= storm.i2c.OK then
        print("Could not communicate with register: " .. rv1)
        return nil
    end
    -- read register with RSTART
    local rv2 = cord.await(storm.i2c.read, self.port + self.address, storm.i2c.RSTART + storm.i2c.STOP, arr)
    -- check all return values
    if rv2 ~= storm.i2c.OK then
        print("Could not read from register: " .. rv2)
        return nil
    end
    return arr:get(1)
end

function REG:w(reg, value)
    -- create array with address and value
    local arr = storm.array.create(2, storm.array.UINT8)
    arr:set(1, reg)
    arr:set(2, value)
    -- write
    local rv = cord.await(storm.i2c.write, self.port + self.address, storm.i2c.START + storm.i2c.STOP, arr)
    -- check return value
    if rv ~= storm.i2c.OK then
        print("Could not write to register: " .. rv)
        return nil
    end
    return 1
end

return REG
