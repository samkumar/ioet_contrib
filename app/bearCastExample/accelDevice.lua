require "storm"
require "cord"
require "bearcast"
ACC = require "accel"

acc = ACC:new()

ACCEL_GVALUE = 1

acc_calibrate = function()
  local ax, ay, az, mx, my, mz = acc:get()
  ACCEL_GVALUE = az
end

acc_get_mg = function()
  local ax, ay, az, mx, my, mz = acc:get()
  return ax*1000 / ACCEL_GVALUE, ay*1000 / ACCEL_GVALUE, az*1000 / ACCEL_GVALUE 
end

cord.new(function()
	acc:init()
	acc_calibrate()
	SVCD.init("bearcast", function() end)
	BEARCAST.init("Jack's Accelerometer", true)
	print("done init")
	while true do
		ax, ay, az = acc_get_mg()
		print(string.format("ax: %d, ay: %d, az: %d", ax, ay, az))
		datatype = {'number', 'number', 'number'}
		data = {tostring(ax), tostring(ay), tostring(az)}
		template = "accelTemplate.html"
		BEARCAST.sendDeviceData(datatype, data, template)
		cord.await(storm.os.invokeLater, 1000*storm.os.MILLISECOND)
	end
end)


cord.enter_loop()
