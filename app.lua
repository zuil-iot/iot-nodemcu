local module = {}  


function module.handle_message(conn, topic, data)
	if data ~= nil then
		local cmd = util.strsplit('/',topic)[3]
		print (topic .. ": " .. data)
		print ("\tCommand = " .. cmd)
		-- Do something here
	end
end

function module.start ()
	print("Sending registration request");
	local regTopic = config.mqtt.ME .. "/register"
	local regPayload = {}
    regPayload.nodeID = config.ID
	m:publish(regTopic,regPayload,0,0)
end

return module  

