-- Provides support for the accelerometer on the firestorm

local REG = require "i2creg"

-- example
function scan_i2c()
    cord.new(function()
        for i=0x02,0xFE,2 do
            local arr = storm.array.create(1, storm.array.UINT8)
            arr:set(1,0)
            local rv = cord.await(storm.i2c.write,  storm.i2c.INT + i,  storm.i2c.START + storm.i2c.STOP, arr)
            if (rv == storm.i2c.OK) then
                print (string.format("Device found at 0x%02x",i ));
            end
        end
    end)
end

local ACCEL_STATUS = 0x00
local ACCEL_WHOAMI = 0x0D
local ACCEL_XYZ_DATA_CFG = 0x0E
local ACCEL_CTRL_REG1 = 0x2A
local ACCEL_M_CTRL_REG1 = 0x5B
local ACCEL_M_CTRL_REG2 = 0x5C
local ACCEL_WHOAMI_VAL = 0xC7

local ACC = {}

function ACC:new()
   local obj = {port=storm.i2c.INT, addr = 0x3c, reg=REG:new(storm.i2c.INT, 0x3c)}
   setmetatable(obj, self)	-- associate class methods
   self.__index = self
   return obj
end


function ACC:init()
    local tmp = self.reg:r(ACCEL_WHOAMI)
    assert (tmp == ACCEL_WHOAMI_VAL, "accelerometer insane")

    --ok lets put it into standby
    self.reg:w(ACCEL_CTRL_REG1, 0x00);

    --Config magnetometer
    self.reg:w(ACCEL_M_CTRL_REG1, 0x1f)
    self.reg:w(ACCEL_M_CTRL_REG2, 0x20)

    --config accelerometer
    self.reg:w(ACCEL_XYZ_DATA_CFG, 0x01)

    --go out of standby
    self.reg:w(ACCEL_CTRL_REG1, 0x0D)

end

function ACC:get()
    -- lets be efficient and read all 6 values
    local addr = storm.array.create(1, storm.array.UINT8)
    addr:set(1, ACCEL_STATUS)
    local rv = cord.await(storm.i2c.write,  self.port + self.addr,  storm.i2c.START, addr)
    if (rv ~= storm.i2c.OK) then
        print ("ERROR ON I2C: ",rv)
    end
    local dat = storm.array.create(13, storm.array.UINT8)
    rv = cord.await(storm.i2c.read,  self.port + self.addr,  storm.i2c.RSTART + storm.i2c.STOP, dat)
    if (rv ~= storm.i2c.OK) then
        print ("ERROR ON I2C: ",rv)
    end
    local ax = dat:get_as(storm.array.INT16_BE, 1) --this is the SECOND byte
    local ay = dat:get_as(storm.array.INT16_BE, 3)
    local az = dat:get_as(storm.array.INT16_BE, 5)
    local mx = dat:get_as(storm.array.INT16_BE, 7)
    local my = dat:get_as(storm.array.INT16_BE, 9)
    local mz = dat:get_as(storm.array.INT16_BE, 11)
    return ax, ay, az, mx, my, mz
end
return ACC