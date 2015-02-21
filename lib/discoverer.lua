require "storm"
NQC = require "nqclient"

local Discoverer = {}

function Discoverer:new(service_found, service_lost, dport, iport)
    dport = dport or 1525
    iport = iport or 1526
    setmetatable(self, {})
    
    -- Maps an ip address to a list of services
    self.discovered_services = {}
    
    self.dsock = storm.net.udpsocket(dport, function (payload, ip, port)
        if not self.discovered_services[ip] then
            self.discovered_services[ip] = {}
        end
        local old_payload = self.discovered_services[ip][port]
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
        end
        self.discovered_services[ip][port] = payload
    end)
    
    self.nqc = NQC:new(iport)
end

function Discoverer:invoke(ip, port, name, args, callback)
    local msg = storm.mp.pack({name, args})
    self.nqc:sendMessage(msg, ip, port, 1500, 50 * storm.os.MILLISECOND, nil, function (message, ip, port)
        message["_id"] = nil
        callback(message, ip, port)
    end)
end

function Discoverer:close()
    self.dsock.close()
    self.nqc:close()
end

return Discoverer
