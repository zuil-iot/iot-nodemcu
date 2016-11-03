local module = {}
local m = nil

module.cb_success = nil
module.cb_on_message = nil


-- Send to broker
local function send(cmd,msg)
	-- Set topic
	local topic = config.mqtt.ME .. "/" .. cmd
	-- Set up message
	if msg == nil then
		msg = {}
	end
	msg.nodeID = config.ID
	-- Send
	m:publish(topic,msg,0,0)
end

-- Ping broker
local function send_ping()
	send("ping",nil);
end

-- Subscribe to my topics and register myself
local function register_myself()
    print("Subscribing to my topics")
	m:subscribe(config.mqtt.ME .. "/+",0,function(conn)
		print("Successfully subscribed to data endpoint")
		-- Register callback for messages
		m:on("message", module.cb_on_message)
		module.cb_success();
	end)
end

local function cb_connect_success (con)
	print("\t\tSuccess")
	-- Register
	register_myself()
	-- Setup Ping Timer
	tmr.alarm(6, config.mqtt.PING_TIME, tmr.ALARM_AUTO, send_ping)
end
local function cb_connect_failure (con, reason)
	print("\t\tFailed [Code = "..reason.."]")
end

function module.start()
	print("Starting MQTT...")
	-- Create client
	m = mqtt.Client(config.ID, 120)
	-- Connect to broker
	print("\tConnecting to " .. config.mqtt.HOST .. ":" .. config.mqtt.PORT)
	m:connect(config.mqtt.HOST, config.mqtt.PORT, 0, 1, cb_connect_success, cb_connect_failure)
end

return module

