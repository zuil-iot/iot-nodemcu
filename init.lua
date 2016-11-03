app = require("app")  
config = require("config")  
wifi_setup = require("wifi_setup")
mqtt_setup = require("mqtt_setup")
util = require("util")

wifi_setup.start(mqtt_setup.start)
