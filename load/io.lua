module = {}
local my_env = env.io

function module.setPin(pin,on)
	local pinType = state.config.pins[pin].type
	if pinType == "gpio" then
		local v = gpio.HIGH
		local reqStatus = "off"
		if on then
			reqStatus = "on"
			v = gpio.LOW
		end
		local i = state.config.pins[pin].index
		print ("Set Pin ["..pin.."/"..i.."/"..v.."] = ",reqStatus)
		gpio.write(i,v)
		state.cur_state.pins[pin].v = on;
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

function module.readPin(pin)
	local pinType = state.config.pins[pin].type
	local pinIndex = state.config.pins[pin].index
	local pinInvert = state.config.pins[pin].invert
	local changed = false
	local v = "na"
	local sent = state.sent_state.pins[pin].val
	
	
	if pinType == "gpio" then
		local pv = gpio.read(pinIndex)
		v = (pv == gpio.LOW)
		if pinInvert then
			v = not v
		end
		if (v ~= sent) then changed = true end
	elseif pinType == "adc" then
		local vMin = 0
		local vMax = 1024
		local vScale = vMax - vMin
		local pinSendDelta = state.config.pins[pin].send_delta
		if (pinSendDelta == nil) then pinSendDelta = my_env.DEFAULT_SEND_DELTA end
		v = adc.read(pinIndex)
		if pinInvert then
			v = vMax - v
		end
		if (sent == 'na') then changed = true
		else
			local deltaPct = math.abs(v-sent)*100/vScale
			if (deltaPct > pinSendDelta ) then changed = true end
		end
	elseif pinType == "dht" then
		local status, temp, humi,temp_dec,humi_dec = dht.read(pinIndex)
		v = {}
		if status == dht.OK then
		v.temp = temp*9/5+32
		v.humi = humi
		v.status = "ok"
		elseif status == dht.ERROR_CHECKSUM then
			print ("DHT Error: Checksum")
			v.status = "err_checksum"
			v.status = "err_checksum"
		elseif status == dht.ERROR_TIMEOUT then
			print ("DHT Error: Timeout")
			v.status = "err_timeout"
		end
		
		if (sent == 'na') then changed = true
		elseif (v.status ~= sent.status) then changed = true
		elseif (v.temp ~= sent.temp) then changed = true
		elseif (v.humi ~= sent.humi) then changed = true
		end
		--print ("Read Pin ["..pin.."] = ",cjson.encode(v),"{",cjson.encode(sent),":",changed,"}")
	end
	state.cur_state.pins[pin].val = v
	-- print ("Read Pin ["..pin.."] = ",v,"{",sent,":",changed,"}")
	return changed
end

function module.updateAndSend()
	local changed = false
	local stream = false
	local stream_data = {}
	stream_data.pins = {}
	for p, c in pairs(state.config.pins) do
		-- Read pin and note changes
		if (module.readPin(p)) then
			print ("Pin Changed: ",p)
			changed = true
			state.sent_state.pins[p].val = state.cur_state.pins[p].val
		end
		-- Check to see if we need to stream
		if (c.stream) then
			state.stream.pins[p] = state.stream.pins[p] - my_env.UPDATE_TIME
			if state.stream.pins[p] < my_env.UPDATE_TIME/2 then
				-- Time to send stream
				state.stream.pins[p] = c.stream*1000
				s = {}
				s.pin = p
				s.val = state.cur_state.pins[p].val
				table.insert(stream_data.pins,s)
				stream = true
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

function module.init(pins)

	-- Clear state tables
	state.config.pins = {}
	state.cur_state.pins = {}
	state.req_state.pins = {}
	state.sent_state.pins = {}
	
	-- Setup each pin
	for p, c in pairs(pins) do
		print ("Config pin: ",p)
		
		-- Setup in tables
		state.req_state.pins[p] = { }
		state.req_state.pins[p].val = "na"
		state.cur_state.pins[p] = { }
		state.cur_state.pins[p].val = "na"
		state.sent_state.pins[p] = { }
		state.sent_state.pins[p].val = "na"
		state.config.pins[p] = c
		
		-- Check whether to stream
		if (c.stream) then 
			state.stream.pins[p] = my_env.INITIAL_STREAM_DELAY	-- Force stream send N seconds after boot up
		end
		
		-- Set type and mode
		if c.type == "gpio" then
			if c.mode == "in" then gpio.mode(c.index, gpio.INPUT,gpio.PULLUP)
			elseif c.mode == "out" then gpio.mode(c.index, gpio.OUTPUT)
			end
		elseif c.type == "adc" then
			-- Make sure send_delta is set
			if (state.config.pins[p].send_delta == nil) then
				state.config.pins[p].send_delta = config.pins.DEFAULT_SEND_DELTA
				end
			-- Set to ADC mode and reboot if needed
			if adc.force_init_mode(adc.INIT_ADC) then
				node.restart()
				return
			end
		elseif c.type == "dht" then
			-- Nothing to do for setup
		end
	end

end


function module.set(pins)
	-- Set specified pins to requested state
	for pin,req in pairs (pins) do
		state.req_state.pins[pin].var = req.val
		module.setPin(pin,req.val)
	end
end


return module