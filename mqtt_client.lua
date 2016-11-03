local module = {}
local cfg = config.mqtt
local me = nil
local m = nil

module.cb_success = nil
module.cb_on_message = nil


-- Send to broker
local function send(cmd,msg)
	-- Set topic
	local topic = me .. "/" .. cmd
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

-- Subscribe to my topics and register device
local function register_myself()
    print("Subscribing to my topics")
	m:subscribe(me .. "/+",0,function(conn)
		print("Successfully subscribed to data endpoint")
		-- Register callback for messages
		m:on("message", module.cb_on_message)
		module.cb_success();
	end)
end

-- Successful connect
local function cb_connect_success (con)
	print("\t\tSuccess")
	-- Register
	register_myself()
	-- Setup Ping Timer
	tmr.alarm(cfg.timer, cfg.PING_TIME, tmr.ALARM_AUTO, send_ping)
end
-- Failed connect
local function cb_connect_failure (con, reason)
	print("\t\tFailed [Code = "..reason.."]")
end

--
-- Start
--
function module.start()
	print("Starting MQTT...")
	-- Create client
	me = cfg.ENDPOINT .. config.ID
	m = mqtt.Client(config.ID, 120)
	-- Connect to broker
	print("\tConnecting to " .. cfg.HOST .. ":" .. cfg.PORT)
	m:connect(cfg.HOST, cfg.PORT, 0, 1, cb_connect_success, cb_connect_failure)
end

return module

