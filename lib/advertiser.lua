require "storm"
NQS = require "nqserver"

local Advertiser = {}

function Advertiser:new(id, portFrom, portTo)
    portFrom = portFrom or 1526
    self.portTo = portTo or 1525
    setmetatable(self, {})
    self.serviceList = {["id"] = id}
    self.functionMap = {}
    
    self.nqs = NQS:new(portFrom, function (message, ip, port)
        name = message[1]
        args = message[2]
        return {self.functionMap[name](unpack(args))}
    end)
    
    return self
end

function Advertiser:addService(name, supc, desc, func)
    self.serviceList[name] = {["s"] = supc, ["desc"] = desc}
    self.functionMap[name] = func
end

function Advertiser:rmService(name)
    self.serviceList[name] = nil
    self.functionMap[name] = nil
end

function Advertiser:advertise()
    msg = storm.mp.pack(self.serviceList)
    storm.net.sendto(self.nqs.socket, msg, "ff02::1", self.portTo)
end

function Advertiser:advertise_repeatedly(delay)
    if self.repeated then
        storm.os.cancel(self.repeated)
    end
    self.repeated = storm.os.invokePeriodically(delay, function ()
        self:advertise()
    end)
end

function Advertiser:close()
    if self.repeated then
        storm.os.cancel(self.repeated)
    end
    self.nqs:close()
end

return Advertiser
