local module = {}  

--- Predefine functions
local validate_message
local enable_commands
local setPin

---
local ledPinReady = 0
local ledPinWifi = 4


--
-- Inbound commands (to)
--

-- config
local function do_config(req)
	print("\t\t\tInitializing")
	enable_commands()
	setPin(ledPinReady,true)
	print ("\t\t\t\tReady to go, Sparky!")
end

-- write
local function do_write(req)
	for i,pinInfo in ipairs(req.pins) do
		setPin(pinInfo.pin,pinInfo.on)
	end
end

-- read
local function do_read(req)
	setPin(ledPinReady,false)
end

---
--- Outbound commands (from)
---

-- register
local function do_register()
    print("\tRegistering with server")
	mqttClient.subscribe("config",do_config)
    mqttClient.send("register",nil)
end

-- state
local function do_state()
end

-- update
local function do_update()
end

-- event
local function do_event()
end

-- alert
local function do_alert()
end



--
-- Special commands
--





enable_commands = function()
	
	mqttClient.subscribe("read")
	mqttClient.subscribe("write")
end


validate_message =  function(msg)
	if (msg == nil) then
		-- No data
        print ("\t\tError [empty data]")
	else
		print (msg)
		-- Convert to JSON
		local req = cjson.decode(msg)
		if (req.deviceID == nil) then
			-- deviceID missing from message
			print ("\t\tMissing deviceID in message")
        elseif (req.deviceID ~= config.ID) then
			-- Wrong deviceID
            print ("\t\tError [Wrong NodeID "..req.deviceID..":"..config.ID.."]")
		else
			-- All good so far, return JSON object
			return req
		end
	end
	return nil
end

local function handle_message(conn, topic, msg)
	local req = validate_message(msg)
	if ( req ~= nil ) then
		local topicFields = util.strsplit(topic,'/')
		local cmd = topicFields[4]
		if (cmd == nil) then print ("Error [no cmd]")
		elseif (cmd == "config") then do_config(req)
		elseif (cmd == "write") then do_write(req)
		elseif (cmd == "read") then do_read(req)
		else print ("Error [unknown command]: <"..cmd..">")
		end
	end
	
end


-- IO
setPin = function(pin,on)
	gpio.mode(pin,gpio.OUTPUT)
	local reqStatus = "off"
	if (on) then reqStatus = "on" end
	print ("Set Pin ["..pin.."] = "..reqStatus)
	local state
	if on then state = gpio.LOW else state = gpio.HIGH end
	gpio.write(pin,state)
end


function module.start ()
    print("Starting App")
	setPin(ledPinReady,false)
	setPin(ledPinWifi,true)
	mqttClient.set_message_cb(handle_message)
    do_register()
end

return module  

