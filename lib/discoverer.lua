require "storm"
NQC = require "nqclient"

local Discoverer = {}

function Discoverer:new(service_found, service_lost, timeout, dport, iport)
    timeout = timeout or 300 * storm.os.SECOND
    dport = dport or 1525
    iport = iport or 1526
    self.dport = dport
    self.iport = iport
    setmetatable(self, {})
    
    -- Maps an ip address to a list of services
    self.discovered_services = {}
    self.timeouts = {}
    
    self.dsock = storm.net.udpsocket(dport, function (payload, ip, port)
        payload = storm.mp.unpack(payload)
        local old_payload = self.discovered_services[ip]
        local old_timeout = self.timeouts[ip]
        if old_timeout then
            storm.os.cancel(old_timeout)
        end
        local discovered_services = self.discovered_services
        local timeouts = self.timeouts
        self.timeouts[ip] = storm.os.invokeLater(timeout, function ()
            local toremove = discovered_services[ip]
            discovered_services[ip] = nil
            timeouts[ip] = nil
            for k, v in pairs(toremove) do
                if k ~= "id" then
                    service_lost(ip, port, toremove["id"], k, v)
                end
            end
        end)
        if old_payload then
            for k, v in pairs(old_payload) do
                if not payload[k] and k ~= "id" then
                    service_lost(ip, port, old_payload["id"], k, v)
                end
            end
            for k, v in pairs(payload) do
                if not old_payload[k] and k ~= "id" then
                    service_found(ip, port, payload["id"], k, v)
                end
            end
        else
            for k, v in pairs(payload) do
                if k ~= "id" then
                    service_found(ip, port, payload["id"], k, v)
                end
            end
        end
        self.discovered_services[ip] = payload
    end)
    
    self.nqc = NQC:new(iport)
    
    return self
end

function Discoverer:invoke(ip, name, args, callback)
    local msg = {name, args}
    self.nqc:sendMessage(msg, ip, self.iport, 1500, 50 * storm.os.MILLISECOND, nil, function (message, ip, port)
        message["_id"] = nil
        callback(message, ip, port)
    end)
end

function Discoverer:resolve(str)
    local matches = {}
    local index
    for ip, servicetable in pairs(self.discovered_services) do
        index = 1
        for name, service in pairs(servicetable) do
            if name == str or service["s"] == str then
                if index == 1 then
                    matches[ip] = {name}
                else
                    matches[ip][index] = name
                end
                index = index + 1
            end
        end
    end
    return matches
end

function Discoverer:close()
    storm.net.close(self.dsock)
    self.nqc:close()
end

return Discoverer
