local module = {}
m = nil

-- Ping broker
local function send_ping()
	m:publish(config.mqtt.PING_TOPIC,config.mqtt.PING_MSG,0,0)
end

-- Subscribe to my topics and register myself
local function register_myself()
    print("Subscribing to my topics")
	m:subscribe(config.mqtt.ME .. "/+",0,function(conn)
		print("Successfully subscribed to data endpoint")
		-- Register callback for messages
		m:on("message", app.handle_message)
		app.start();
	end)
end

function module.start()
    print("Starting MQTT...")
	-- Create client
	m = mqtt.Client(config.ID, 120)
	-- Connect to broker
    print("\tConnecting to " .. config.mqtt.HOST .. ":" .. config.mqtt.PORT)
	m:connect(config.mqtt.HOST, config.mqtt.PORT, 0, 1, function(con)
		-- Register
		register_myself()
		-- Setup Ping Timer
		tmr.alarm(6, config.mqtt.PING_TIME, tmr.ALARM_AUTO, send_ping)
        end)
end

return module

