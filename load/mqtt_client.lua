local module = {}
local my_env = env.mqtt
local me = nil
m = nil

cb_success = nil
cb_message = nil


-- Send to broker
function module.send(msg_type,data)
	-- Set topic
	local topic = me .. "/from/" .. msg_type
	-- Set up message
	local msg = {}
	msg.msg_type = msg_type
	msg.deviceID = env.ID
	if (data == nil) then data = {} end
	msg.data = data
	-- Encode message
	ok, json = pcall(cjson.encode, msg)
	if ok then
	-- Send
		if (msg_type ~= "ping") then print("Send: "..msg_type) end
		m:publish(topic,json,0,0)
		tmr.interval(my_env.TIMER, my_env.PING_TIME) -- Reset ping timer
	else
		print("Failed to encode!")
	end
end
 
-- Ping broker
local function send_ping()
	module.send("ping",nil);
end

-- Set callbacks
function module.set_message_cb(cb)
	if (cb ~= nil) then cb_message=cb end
end
function module.set_success_cb(cb)
	if (cb ~= nil) then cb_success=cb end
end

-- Successful connect
local function cb_connect_success (con)
	print("\t\tRegistered as "..env.ID)
	-- Setup Ping Timer
	print("\t\tStarting ping timer")
	tmr.alarm(my_env.TIMER, my_env.PING_TIME, tmr.ALARM_AUTO, send_ping)
	-- Set up message handler
	if (cb_message ~= nil) then
		print("\t\tSetting up message handler")
		m:on("message", cb_message)
	end
	-- Subscribe to incoming messages
	local in_topic = me.."/to"
	print("\t\tSubscribing to: "..in_topic)
	m:subscribe(in_topic,0,function(conn)
		print("\t\t\tSubscribed")
		-- Done. Run success callback
		if (cb_success ~= nil) then cb_success() end
	end)
end
-- Failed connect
local function cb_connect_failure (con, reason)
	print("\t\tMQTT Connect failed [Code = "..reason.."]")
end

--
-- Start
--
function module.start()
	print("Starting MQTT...")
	-- Create client
	me = my_env.ENDPOINT .. env.ID
	m = mqtt.Client(env.ID, my_env.KEEPALIVE)
	print("MQTT\t"..node.heap())
	-- Connect to broker
	print("\tConnecting to " .. my_env.HOST .. ":" .. my_env.PORT)
	m:connect(my_env.HOST, my_env.PORT, 0, 1, cb_connect_success, cb_connect_failure)
end

return module

