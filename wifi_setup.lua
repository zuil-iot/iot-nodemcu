local module = {}
local success_cb = nil

--
-- Wifi Setup
--
--
local function wifi_wait_ip()  
  if wifi.sta.getip()== nil then
    print("IP unavailable, Waiting...")
  else
    tmr.stop(1)
    print("\n====================================")
    print("ESP8266 mode is: " .. wifi.getmode())
    print("MAC address is: " .. wifi.ap.getmac())
    print("IP is "..wifi.sta.getip())
    print("====================================")
    success_cb()
  end
end

local function wifi_start(list_aps)  
    if list_aps then
        print ("\t Scanning AP list")
        for key,value in pairs(list_aps) do
            if config.wifi.SSID and config.wifi.SSID[key] then
                wifi.setmode(wifi.STATION);
                wifi.sta.config(key,config.wifi.SSID[key])
                print("Connecting to " .. key .. " ...")
                wifi.sta.connect()
                --config.wifi.SSID = nil  -- can save memory
                tmr.alarm(1, 2500, 1, wifi_wait_ip)
            end
        end
    else
        print("Error getting AP list")
    end
end




-- Start setup
function module.start(s_cb)  
	success_cb = s_cb
	print("Configuring Wifi ...")
	wifi.setmode(wifi.STATION);
    print("\tLooking for APs ...")
	wifi.sta.getap(wifi_start)
end


return module  


