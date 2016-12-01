local module = {}

module.PREFIX = "nodemcu"
module.ID = module.PREFIX .. "_" .. node.chipid()
module.HW = "nodemcu"
module.SW = "v0.3.4"

module.wifi = {}
module.wifi.SSID = {}  
module.wifi.SSID["Okapi"] = "Kenz123123"
module.wifi.TIMER = 0					-- HW timer #

module.mqtt = {}
module.mqtt.HOST = "216.50.168.59"
module.mqtt.PORT = 1883
module.mqtt.ENDPOINT = "devices/"  
module.mqtt.KEEPALIVE = 20				-- Seconds
module.mqtt.PING_TIME = module.mqtt.KEEPALIVE / 4 * 1000
module.mqtt.TIMER = 1					-- HW timer #

module.io = {}
module.io.TIMER = 2						-- HW timer #
module.io.UPDATE_TIME = 1000			-- mSec
module.io.DEFAULT_SEND_DELTA = 5		-- %
module.io.INITIAL_STREAM_DELAY = 10		-- Seconds


return module  
