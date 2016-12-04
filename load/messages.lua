local module = {}  

--- Predefine functions
local validate_message


---
--- Outbound commands (from)
---

-- register
function module.send_register()
    print("\tRegistering with server")
	local msg = {}
	msg.deviceID = env.ID
	msg.sw_version = env.SW
    mqttClient.send("register",msg)
end

-- state
function module.send_state ()
	local msg = {}
	msg.cur_state = state.cur_state
	msg.status = state.status
	mqttClient.send("state",msg)
end

-- update
function module.send_stream(m)
	local msg = {}
	msg.stream = m
	mqttClient.send("stream",msg)
end

-- event
function module.send_event()
end

-- alert
function module.send_alert()
end



--
-- Inbound commands (to)
--

-- config
local function do_config(req)
	print("\t\t\tGot new config")
	state.registered = req.registered;
	-- Init I/O
	io.init(req.config.io)
	io.set(req.req_state.io)
	io.updateAndSend()
	-- Check registered
	if (state.registered) then
		print ("\t\t\t\tReady to go, Sparky!")
		io.doTimer(true);
	else
		print ("\t\t\t\tNot registered")
		io.doTimer(false);
	end
end

-- write
local function do_write(req)
	io.set(req.req_state.io)
	io.updateAndSend()
end

-- read
local function do_read(req)
	io.updateAndSend()
end

-- unregister
local function do_unregister()
	state.registered = false;
end


--
-- Special commands
--

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
        elseif (req.deviceID ~= env.ID) then
			-- Wrong deviceID
            print ("\t\tError [Wrong NodeID "..req.deviceID..":"..env.ID.."]")
        elseif (req.msg_type == nil) then
			-- No Message Type
            print ("\t\tError [No Command in message")
		else
			-- All good so far, return JSON object
			return req
		end
	end
	return nil
end

function module.handle_message(conn, topic, msg)
	local req = validate_message(msg)
	if ( req ~= nil ) then
		local msg_type = req.msg_type
		local msg_data = req.data
		if (msg_type == nil) then print ("Error [no msg_type]")
		elseif (msg_type == "config") then do_config(msg_data)
		elseif (state.registered) then
			if (msg_type == "write") then do_write(msg_data)
			elseif (msg_type == "read") then do_read(msg_data)
			else print ("Error [unknown command]: <"..msg_type..">")
			end
		else print ("Error [not registered]: <"..msg_type..">")
		end
	end	
end


function module.start ()
    print("Starting Application")
    module.send_register()
end

return module  

