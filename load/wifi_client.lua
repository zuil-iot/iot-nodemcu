local module = {}
local my_env = env.wifi
module.cb_success = nil


--
-- Wifi Setup
--
--
local function wifi_wait_ip()  
  if wifi.sta.getip()== nil then
    print("IP unavailable, Waiting...")
  else
    tmr.stop(my_env.TIMER)
    print("\n====================================")
    print("ESP8266 mode is: " .. wifi.getmode())
    print("MAC address is: " .. wifi.ap.getmac())
    print("IP is "..wifi.sta.getip())
    print("====================================")
	if (module.cb_success ~= nill) then module.cb_success() end
  end
end

local function wifi_connect(ap_list)  
    if ap_list then
	tmr.stop(my_env.TIMER)
        print ("\t\t Scanning AP list")
        for key,value in pairs(ap_list) do
            if my_env.SSID and my_env.SSID[key] then
                wifi.setmode(wifi.STATION);
                wifi.sta.config(key,my_env.SSID[key])
                print("Connecting to " .. key .. " ...")
                wifi.sta.connect()
                --my_env.SSID = nil  -- can save memory
                tmr.alarm(my_env.TIMER, 2500, 1, wifi_wait_ip)
            end
        end
    else
        print("\t\tNo APs found. Waiting...")
    end
end

local function wifi_get_aps()
	wifi.sta.getap(wifi_connect)
end


-- Set callbacks
function module.set_success_cb(cb)
	if (cb ~= nil) then module.cb_success=cb end
end

--
-- Start
--
function module.start()  
	tmr.stop(my_env.TIMER)
	print("Configuring Wifi ...")
	wifi.setmode(wifi.STATION);
	print("\tLooking for APs ...")
	tmr.alarm(my_env.TIMER, 2500, 1, wifi_get_aps)
end


return module  

