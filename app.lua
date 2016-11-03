local module = {}  
local initialized = false


--
-- Special commands
--
local function do_init()
	print("\t\t\tInitializing")
	initialized = true
end

local function do_register()
	print("\tSending registration request")
	mqttClient.send("register",nil)
end

--
-- Normal commands
--
local function do_xxx(data)
end

local function do_yyy(data)
end

--
-- Parse command
--
local function do_cmd(cmd,data)
	if (cmd == "xxx") do_xxx(data)
	if (cmd == "yyy") do_yyy(data)
	end
end

--
-- Handle incoming message
--
function module.handle_message(conn, topic, data)
	print ("\tMessage Received. ["..topic .. ": " .. data.."]")
	if data == nil then
		print ("\t\tError [empty data]")
	else
		-- Extract fields from topic
		local topicFields = util.strsplit('/',topic)
		local nodeID = topicFields[2]
		local cmd = topicFields[3]
		--
		-- Process message
		--
		-- Check for valid ID
		if (nodeID ~= config.ID) then
			print ("\t\tError [Wrong NodeID]")
			return
		end
		print ("\t\tCommand = " .. cmd)
		-- Process commands
		-- init
		if (cmd == "init" ) then do_init()
		-- Skip if not initialized
		else if (not initialized) then print ("\t\tNot initialized. Ignoring command")
		else do_cmd(cmd,data)
		end
	end
end


function module.start ()
	print("Starting App")
	do_register()
end

return module  

