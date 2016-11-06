print("Start\t"..node.heap())
util = require("util")
print("Util\t"..node.heap())
config = require("config")
print("Config\t"..node.heap())
wifiClient = require("wifi_client")
print("Wifi\t"..node.heap())
mqttClient = require("mqtt_client")
print("MQTT\t"..node.heap())
app = require("app")
print("App \t"..node.heap())

wifiClient.cb_success = mqttClient.start
mqttClient.cb_success = app.start
mqttClient.cb_on_message = app.handle_message

wifiClient.start()
 