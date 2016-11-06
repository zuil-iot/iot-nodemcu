local module = {}
local cfg = config.mqtt
local me = nil
m = nil

module.cb_success = nil


-- Send to broker
function module.send(cmd,msg)
	-- Set topic
	local topic = me .. "/from/" .. cmd
	-- Set up message
	if msg == nil then
		msg = {}
	end
	msg.nodeID = config.ID
	-- Encode message
	ok, json = pcall(cjson.encode, msg)
	if ok then
	-- Send
		if (cmd ~= "ping") then print("Send: "..cmd) end
		m:publish(topic,cjson.encode(msg),0,0)
	else
		print("Failed to encode!")
	end
end

-- Ping broker
local function send_ping()
	module.send("ping",nil);
end

-- Subscribe to a topic (cmd) and register message callback (message_cb)
function module.subscribe(cmd)
	m:subscribe(me .. "/to/"..cmd,0,function(conn)
		-- Register callback for messages
		print("Subscribed to: ".. cmd)	-- <<<<<<<<<<<<<<< BUG! cmd is the same for all callbacks if done quickly
	end)
end

function module.set_message_cb(message_cb)
	if (message_cb ~= nil) then m:on("message", message_cb) end
end

-- Successful connect
local function cb_connect_success (con)
	print("\t\tRegistered as "..config.ID)
	-- Setup Ping Timer
	tmr.alarm(cfg.TIMER, cfg.PING_TIME, tmr.ALARM_AUTO, send_ping)
	if (module.cb_success ~= nil) then module.cb_success() end
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
	me = cfg.ENDPOINT .. config.ID
	m = mqtt.Client(config.ID, cfg.KEEPALIVE)
	print("MQTT\t"..node.heap())
	-- Connect to broker
	print("\tConnecting to " .. cfg.HOST .. ":" .. cfg.PORT)
	m:connect(cfg.HOST, cfg.PORT, 0, 1, cb_connect_success, cb_connect_failure)
end

return module

