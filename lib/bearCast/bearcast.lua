require "cord"
require "svcd"
require "storm"

BEARCAST = {
	service_id = 0x3030,
	attr_id = 0x4040,
	listen_port = 7780,
	server_port = 7788,

	isListening = true,
	verbose = false,
	node_id = storm.os.getipaddrstring(),
	mapping = {},
	countmapping = {},
	agentmapping = {},
	sock = nil
}

BEARCAST.init  = function(node_id_m, verbose_m)
	if (node_id_m ~= nil) then
		BEARCAST.node_id = node_id_m
	end
	if (verbose_m == true) then
		BEARCAST.verbose = true
	end
	BEARCAST.sock = storm.net.udpsocket(BEARCAST.listen_port, BEARCAST.listener)
	their_received = SVCD.advert_received
	SVCD.advert_received = function(pay, srcip, srcport, lqi, rssi)
		their_received(pay, srcip, srcport, lqi, rssi)
		local adv = storm.mp.unpack(pay)
			if BEARCAST.verbose then print (string.format("Service advertisment %s", srcip)) end
				for k,v in pairs(adv) do
					if k == "id" then
							if BEARCAST.verbose then print ("ID="..v) end
					else
							if BEARCAST.verbose then print (string.format("  0x%04x:",k)) end
						if k == BEARCAST.service_id then
							for kk,vv in pairs(v) do
								if (vv == BEARCAST.attr_id) then
									BEARCAST.agentmapping[srcip] = storm.os.now(storm.os.SHIFT_16)
								end
								if BEARCAST.verbose then print (string.format("   >%d: 0x%04x", kk, vv)) end
							end
						end
					end
				end
	end
	BEARCAST.isListening = true
end

BEARCAST.listener = function(payload, srcip, srcport, lqi, rssi)
	if (BEARCAST.isListening) then
		if BEARCAST.verbose then print('received', srcip, lqi) end
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
	if BEARCAST.verbose then print("post") end
	local closestIp = BEARCAST.getClosest()
	if BEARCAST.verbose then print('after closest') end
	if (closestIp == nil) then
		print("No display found")
		return 1
	end
	local message = string.format('{"data":"%s","scan":["%s"],"req_type":"cast","name":"%s"}', msg, closestIp,BEARCAST.node_id) 	
	if BEARCAST.verbose then print('message: ', message, ' port:', BEARCAST.server_port) end
	local rv = storm.net.sendto(BEARCAST.sock, message, closestIp, BEARCAST.server_port)
	if BEARCAST.verbose then print("end post ", rv) end
	return 0
end

-- Send device data to the device specific section
-- Data Type: A list of the types of each data point, must match the template requirement in string format
-- e.g. datatype : {"str", "image", "html"}
-- Data: A list of actual data being sent, must match the data type in string format
-- e.g. data: {"hello", "http://shell.storm.pm/test.jpg", "http://shell.storm.pm/hi.html"}
-- Template: The template used to render the data, could be an URL or a preset KEY
-- e.g. template: "http://shell.storm.pm/ricecooker_template.html" or "ricecooker_template"
BEARCAST.sendDeviceData = function(datatype, data, template)
	if type(datatype) ~= "table" or type(data) ~= "table" or type(template) ~= "string" then
		print ("Wrong input type") 
		return 1
	end
	local closestIp = BEARCAST.getClosest()
	if (closestIp == nil) then
		print("No display found")
		return 1
	end
	local datatype_str = table.concat(datatype, '","')
	local data_str = table.concat(data, '","')
	local message = string.format('{"data":{"datatype":["%s"],"data":["%s"],"template":"%s"},"scan":["%s"],"req_type":"device"}', datatype_str, data_str, template, closestIp)
	if BEARCAST.verbose then print('message: ', message) end
	local rv = storm.net.sendto(BEARCAST.sock, message, closestIp, BEARCAST.server_port)
	if BEARCAST.verbose then print("end post ", rv) end
	return 0
end

BEARCAST.getClosest = function()
	if BEARCAST.verbose then print("getClosest") end
	local currMax = 0
	local currMaxIp = nil
	for ip, lqi in pairs(BEARCAST.mapping) do
		if lqi > currMax then
			currMax = lqi
			currMaxIp = ip
		end
	end
	BEARCAST.isListening = false
	cord.await(storm.os.invokeLater, 10*storm.os.MILLISECOND)
	BEARCAST.mapping = {}
	BEARCAST.countmapping = {}
	BEARCAST.isListening = true
	if BEARCAST.verbose then print("end getclosest", currMaxIp) end
	return currMaxIp
	
end
