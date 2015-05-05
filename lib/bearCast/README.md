#BEARCAST Storm Library#

##Quick Start##

This is bearcast library, to use the library you should call

```
SVCD.init()
```

before calling

```
BEARCAST.init("AppName")
```

Then user can call:

```
BEARCAST.postToClosestDisplay(msg)
```

msg: is a lua string to be posted underthe "Message" section of nearest BearCast display. 

**Example: A Beeper that beeps as soon as possible**

```
require "storm"
require "cord"
require "bearcast"
sh = require "stormsh"

--sh.start()
cord.new(function()
	SVCD.init("bearcast", function() end)
	BEARCAST.init("Beeper")
	while true do
		print('beeping')
		BEARCAST.postToClosestDisplay('beep')
		cord.await(storm.os.invokeLater, 1000*storm.os.MILLISECOND)
	end
end)


cord.enter_loop()
```

##Library API:##

**BEARCAST.init  = function(node_id, verbose)**

Initialize BearCast display library, need SVCD to be init before this. 

```
node_id: a string to indicate the name of the node, if nil, it will be the node's IP address
verbose: a boolean indicating if the library should output extra debug information
```

**BEARCAST.postToClosestDisplay = function(msg)**

Post to the nearest display's message section. 
```
msg: the msg to be posted to the message section of the bearCast display
```

**BEARCAST.sendDeviceData = function(datatype, data, template)**

Send device data to the device specific section on the bearCast display
```
Data Type: A list of the types of each data point, must match the template requirement in string format 
-- e.g. datatype : {"str", "image", "html"}
Data: A list of actual data being sent, must match the data type in string format
-- e.g. data: {"hello", "http://shell.storm.pm/test.jpg", "http://shell.storm.pm/hi.html"}
Template: The template used to render the data, could be an URL or a preset KEY
-- e.g. template: "http://shell.storm.pm/ricecooker_template.html" or "ricecooker_template"
```

##EXTRA: RESTFul API##

```
POST:
http://shell.storm.pm:7789/cast - for casting data
http://shell.storm.pm:7789/heartbeat - for visitor tracking
JSON Format Content:
{“data”:<data to be sent>, “scan”:[<MAC_ADDR>, <MAC_ADDR>, … ]
*list of MAC_ADDR from scan result of local device
*BLE (MAC) or 802.15.4 (IPV6_ADDR of Firestorm)

e.g.
POST http://shell.storm.pm:7789/cast
Content-Type: application/json
{"data":"hello", "scan":["FE80::212:6D02:0:310B"]}
```

Finally if you need to take a further look into our project, please refer to the presentation slides:

https://docs.google.com/presentation/d/1zdC_9RDKD2QBURmZilx-KQfUEJ6MM8m9YZQSHP58IGc/edit?usp=sharing
