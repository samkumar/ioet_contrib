require "cord"
require "svcd"

BEARCAST = {
	service_id = 0x3030,
	attr_id = 0x4040,
	listen_port = 7780,

	isListening = false,
	mapping = {},
	countmapping = {},
	agentmapping = {},
}

BEARCAST.init  = function()
	BEARCAST.sock = storm.net.udpsocket(BEARCAST.listen_port, BEARCAST.listener)
	their_received = SVCD.advert_received
	SVCD.advert_received = function(pay, srcip, srcport, lqi, rssi)
		their_received(pay, srcip, srcport, lqi, rssi)
		local adv = storm.mp.unpack(pay)
    		-- print (string.format("Service advertisment %s", srcip))
    			for k,v in pairs(adv) do
        			if k == "id" then
            				-- print ("ID="..v)
        			else
            				-- print (string.format("  0x%04x:",k))
            			if k == BEARCAST.service_id then
	            			for kk,vv in pairs(v) do
	            				if (vv == BEARCAST.attr_id) then
	            					BEARCAST.agentmapping[srcip] = storm.os.now(storm.os.SHIFT_16)
	            				end
	                			-- print (string.format("   >%d: 0x%04x", kk, vv))
	            			end
	        			end
        			end
    			end
	end
end


BEARCAST.listener = function(payload, srcip, srcport, lqi, rssi)
	if (BEARCAST.isListening) then
		print('received')
		print(srcip, lqi)
		lqi = rssi * 1000
		if srcip == nil or lqi == nil or rssi == nil then
			return
		end
		if BEARCAST.mapping[srcip] == nil then
			BEARCAST.mapping[srcip] = lqi
			BEARCAST.countmapping[srcip] = 1
		else	
			BEARCAST.mapping[srcip] = (BEARCAST.mapping[srcip] * BEARCAST.countmapping[srcip] + lqi)/(BEARCAST.countmapping[srcip] +1)
			BEARCAST.countmapping[srcip] = BEARCAST.countmapping[srcip] + 1
		end
	end
end





BEARCAST.postToClosestDisplay = function(msg)
	print("post")
	local closestIp = BEARCAST.getClosest()
	print('after closest')
	if (closestIp == nil) then
		print("No display found")
		return
	end
	local message = string.format('{"data":"%s","scan":["%s"],"req_type":"cast"}', msg, closestIp) 	
	print('message', message)
	SVCD.write(closestIp, BEARCAST.service_id, BEARCAST.attr_id, message, 300)
	print("end post")
end

BEARCAST.getClosest = function()
	print("getClosest")
	print('received')

	print(srcip, lqi)
	BEARCAST.mapping = {}
	BEARCAST.countmapping = {}
	BEARCAST.isListening = true
	cord.await(storm.os.invokeLater, 2 * storm.os.SECOND)
	BEARCAST.isListening = false
	local currMax = 0
	local currMaxIp = nil
	for ip, lqi in pairs(BEARCAST.mapping) do
		if lqi > currMax then
			currMax = lqi
			currMaxIp = ip
		end
	end
	
	print("end getclosest")
	print(currMaxIp)
	return currMaxIp		
	
end
