BEARCAST Storm Library

This is bearcast library, to use the library you should call

```
SVCD.init()
```

before calling

```
BEARCAST.init()
```

Then user can call:

```
BEARCAST.postToClosestDisplay(msg)
```

msg: is a lua string to be posted underthe "Message" section of nearest BearCast display. 

Example: A Beeper that beeps as soon as possible

```
require "storm"
require "cord"
require "bearcast"

cord.new(function()
	SVCD.init("bearcast", function() end)
	BEARCAST.init()
	while true do
		print('beeping')
		BEARCAST.postToClosestDisplay('beep')
	end
end)

cord.enter_loop()
```

EXTRA: RESTFul API

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
