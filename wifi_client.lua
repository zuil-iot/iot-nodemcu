local module = {}
module.cb_success = nil

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
    module.cb_success()
  end
end

local function wifi_connect(ap_list)  
    if ap_list then
	tmr.stop(1)
        print ("\t\t Scanning AP list")
        for key,value in pairs(ap_list) do
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
        print("\t\tNo APs found. Waiting...")
    end
end

local function wifi_get_aps()
	wifi.sta.getap(wifi_connect)
end



-- Start setup
function module.start()  
	tmr.stop(1)
	print("Configuring Wifi ...")
	wifi.setmode(wifi.STATION);
	print("\tLooking for APs ...")
	tmr.alarm(1, 2500, 1, wifi_get_aps)
end


return module  

