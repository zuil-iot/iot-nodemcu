module = {}
local cfg = config.pins

function module.setPin(pin,on)
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

function module.readPin(pin)
	local pinType = state.config.pins[pin].type
	local pinIndex = state.config.pins[pin].index
	local pinInvert = state.config.pins[pin].invert
	local v = "na"
	if pinType == "gpio" then
		local pv = gpio.read(pinIndex)
		v = (pv == gpio.LOW)
		if pinInvert then
			v = not v
		end
	elseif pinType == "adc" then
		v = adc.read(pinIndex)
		if pinInvert then
			v = 1024 - v
		end
	end
	print ("Read Pin ["..pin.."] = ",v)
	state.cur_state.pins[pin].val = v
end

function module.updateCurrentState()
	for pin, cfg in pairs(state.config.pins) do
		module.readPin(pin)
	end
end

function module.updateAndSend()
	print("Sending state from Pins")
	module.updateCurrentState()
	messages.send_state()
end

function module.init(pins)

	-- Clear state tables
	state.config.pins = {}
	state.cur_state.pins = {}
	state.req_state.pins = {}
	
	-- Setup each pin
	for p, c in pairs(pins) do
		print ("Config pin: ",pin)
		
		-- Setup in tables
		state.req_state.pins[p] = { }
		state.req_state.pins[p].val = "na"
		state.cur_state.pins[p] = { }
		state.cur_state.pins[p].val = "na"
		state.config.pins[p] = c
		
		-- Set type and mode
		if c.type == "gpio" then
			if c.mode == "in" then gpio.mode(c.index, gpio.INPUT,gpio.PULLUP)
			elseif c.mode == "out" then gpio.mode(c.index, gpio.OUTPUT)
			end
		elseif c.type == "adc" then
			if adc.force_init_mode(adc.INIT_ADC) then
				node.restart()
				return
			end
		end
	end
	print("Start Timer ["..cfg.TIMER.."] = "..cfg.UPDATE_TIME.."ms")
	tmr.alarm(cfg.TIMER, cfg.UPDATE_TIME, tmr.ALARM_AUTO, module.updateAndSend)
end


function module.set(pins)
	-- Set specified pins to requested state
	for pin,req in pairs (pins) do
		state.req_state.pins[pin].var = req.val
		module.setPin(pin,req.val)
	end
end


return module