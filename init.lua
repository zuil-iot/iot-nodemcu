app = require("app")  
config = require("config")  
wifiClient = require("wifi_client")
mqttClient = require("mqtt_client")
util = require("util")

wifiClient.cb_success = mqttClient.start
mqttClient.cb_success = app.start
mqttClient.cb_on_message = app.handle_message

wifiClient.start()
