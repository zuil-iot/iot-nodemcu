# iot-nodemcu

## Setup
- Make a copy of the config
	
	cp config.example config.lua
- Edit with your parameters

## Commands

Commands are implemented using MQTT topics. The format of the topic is:
> `/device/<deviceID>/<cmd>`

The payload of the message will differ per command, but should always include
> `{ deviceID:<deviceID }`

The following commands are supported:
### Device --> Server
- register
### Server --> Device
- init
- xxx
- yyy
