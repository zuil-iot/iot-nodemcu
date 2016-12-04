module = {}
local my_env = env.io

function module.setIO(io_name,slot_name,val)
	local ioType = state.config.io[io_name].type
	if ioType == "gpio" then
		local v = gpio.HIGH
		local reqStatus = "off"
		if val then
			reqStatus = "on"
			v = gpio.LOW
		end
		local pin = state.config.io[io_name].pin
		print ("Set I/O ["..io_name.."/"..slot_name.."/"..v.."] = ",reqStatus)
		gpio.write(pin,v)
		state.cur_state.io[io_name].slots[slot_name].val = val;
	end
end

function module.doTimer(start)
	if (start) then
		print("Start Timer ["..my_env.TIMER.."] = "..my_env.UPDATE_TIME.."ms")
		tmr.alarm(my_env.TIMER, my_env.UPDATE_TIME, tmr.ALARM_AUTO, module.updateAndSend)
	else
		print("Stop Timer ["..my_env.TIMER.."]")
		tmr.unregister(my_env.TIMER)
	end
end

function module.readIO(io_name)

	local ioType = state.config.io[io_name].type
	local ioPin = state.config.io[io_name].pin
	local changed = false
	local v = "na"
	--local sent = state.sent_state.pins[pin].val
	
	if ioType == "gpio" then
		local slot_name = "default"
		local invert = state.config.io[io_name].slots[slot_name].invert
		local sent = state.sent_state.io[io_name].slots[slot_name].val
		local pv = gpio.read(ioPin)
		v = (pv == gpio.LOW)
		if invert then
			v = not v
		end
		if (v ~= sent) then changed = true end
		state.cur_state.io[io_name].slots[slot_name].val = v
	elseif ioType == "adc" then
		local slot_name = "default"
		local vMin = 0
		local vMax = 1024
		local vScale = vMax - vMin
		local invert = state.config.io[io_name].slots[slot_name].invert
		local sent = state.sent_state.io[io_name].slots[slot_name].val
		local sendDelta = state.config.io[io_name].slots[slot_name].send_delta
		if (sendDelta == nil) then sendDelta = my_env.DEFAULT_SEND_DELTA end
		v = adc.read(ioPin)
		if invert then
			v = vMax - v
		end
		if (sent == 'na') then
			changed = true
		else
			local deltaPct = math.abs(v-sent)*100/vScale
			if (deltaPct > sendDelta ) then changed = true end
		end
		state.cur_state.io[io_name].slots[slot_name].val = v
	elseif ioType == "dht" then
		local t_sent = state.sent_state.io[io_name].slots.temp.val
		local h_sent = state.sent_state.io[io_name].slots.humi.val
		local t_cur = "na"
		local h_cur = "na"
		
		local status, temp, humi,temp_dec,humi_dec = dht.read(ioPin)
		
		if status == dht.OK then
			t_cur= temp*9/5+32
			h_cur= humi
		elseif status == dht.ERROR_CHECKSUM then
			print ("DHT Error: Checksum")
			t_cur = "err_checksum"
			h_cur = "err_checksum"
		elseif status == dht.ERROR_TIMEOUT then
			print ("DHT Error: Timeout")
			t_cur = "err_timeout"
			h_cur = "err_timeout"
		end
		-- Set current state
		state.cur_state.io[io_name].slots.temp.val = t_cur
		state.cur_state.io[io_name].slots.humi.val = h_cur
		-- Check for change
		if (sent == 'na') then changed = true
		elseif (t_cur ~= t_sent) then changed = true
		elseif (h_cur ~= h_sent) then changed = true
		end
		--print ("Read Pin ["..pin.."] = ",cjson.encode(v),"{",cjson.encode(sent),":",changed,"}")

	end
	-- print ("Read Pin ["..pin.."] = ",v,"{",sent,":",changed,"}")
	return changed
end

function module.updateAndSend()
	local changed = false
	local stream = false
	local stream_data = {}
	stream_data.io = {}
	
	
	for io_name,cfg in pairs (state.config.io) do
		-- Read pin and note changes
		local ioChanged = module.readIO(io_name)
		changed = changed or ioChanged
		for slot_name,slot in pairs (cfg.slots) do
			if (ioChanged) then
				print ("I/O Changed: ",io_name)
				state.sent_state.io[io_name].slots[slot_name].val = state.cur_state.io[io_name].slots[slot_name].val
			end
			if (slot.stream) then
				state.stream.io[io_name].slots[slot_name] = state.stream.io[io_name].slots[slot_name]
					- my_env.UPDATE_TIME
				if state.stream.io[io_name].slots[slot_name] < my_env.UPDATE_TIME/2 then
					-- Time to send stream
					state.stream.io[io_name].slots[slot_name] = slot.stream*1000
					s = {}
					s.io_name = io_name
					s.slot_name = slot_name
					s.val = state.cur_state.io[io_name].slots[slot_name].val
					table.insert(stream_data.io,s)
					stream = true
				end
			end
		end
	end
	
	if (changed) then
		print("Sending state from Pins")
		messages.send_state()
	end
	if (stream) then
		print("Streaming: ",cjson.encode(stream_data))
		messages.send_stream(stream_data)
	end
end

function module.init_tables(io)
	-- Clear state tables
	state.config.io = {}
	state.cur_state.io = {}
	state.req_state.io = {}
	state.sent_state.io = {}
	
	for io_name,cfg in pairs (io) do
		-- Setup I/O Tables
		state.req_state.io[io_name] = {}
		state.cur_state.io[io_name] = {}
		state.sent_state.io[io_name] = {}
		state.stream.io[io_name] = {}
		state.config.io[io_name] = cfg
	
		-- Create slots
		state.req_state.io[io_name].slots = {}
		state.cur_state.io[io_name].slots = {}
		state.sent_state.io[io_name].slots = {}
		state.stream.io[io_name].slots = {}
		
		
		for slot_name,slot in pairs (cfg.slots) do
			-- Setup Slot Tables
			state.req_state.io[io_name].slots[slot_name] = {}
			state.req_state.io[io_name].slots[slot_name].val = "na"
			
			state.cur_state.io[io_name].slots[slot_name] = {}
			state.cur_state.io[io_name].slots[slot_name].val = "na"
			
			state.sent_state.io[io_name].slots[slot_name] = {}
			state.sent_state.io[io_name].slots[slot_name].val = "na"
									
			-- Set defaults if needed
			if cfg.type == "adc" then
				-- Make sure send_delta is set
	print("IO: ",io_name)
	print("Slot: ",slot_name)
	print("Config: ",cjson.encode(state.config.io))
	print("Slot Config: ",cjson.encode(state.config.io[io_name].slots[slot_name]))
				if (state.config.io[io_name].slots[slot_name].send_delta == nil) then
					state.config.io[io_name].slots[slot_name].send_delta = my_env.DEFAULT_SEND_DELTA
				end
			end
			
			-- Check whether to stream
			if (slot.stream) then 
				state.stream.io[io_name].slots[slot_name] = my_env.INITIAL_STREAM_DELAY	-- Force stream send N seconds after boot up
			end
			
		end
	end
end

function module.init(io)
	-- Clear / set up all tables
	module.init_tables(io);
	
	-- Setup each io/slot		
	for io_name,cfg in pairs (io) do
		print ("Config IO: ",io_name)
		-- I/O Setup
		if cfg.type == "gpio" then
			if cfg.mode == "in" then gpio.mode(cfg.pin, gpio.INPUT,gpio.PULLUP)
			elseif cfg.mode == "out" then gpio.mode(cfg.pin, gpio.OUTPUT)
			end
		elseif cfg.type == "adc" then
			-- Set to ADC mode and reboot if needed
			if adc.force_init_mode(adc.INIT_ADC) then
				node.restart()
				return
			end
		elseif cfg.type == "dht" then
			-- Nothing to do for setup
		end
	end
end


function module.set(io)
	-- Set specified pins to requested state
	for io_name,req in pairs (io) do
		for slot_name,slot in pairs (req.slots) do
			state.req_state.io[io_name].slots[slot_name].val = slot.val
			module.setIO(io_name,slot_name,slot.val)
		end
	end
end


return module