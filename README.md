# iot-nodemcu

## Setup
- Make a copy of the config
	
	cp config.example config.lua
- Edit with your parameters

## Commands

Commands are implemented using MQTT topics. The format of the topic is:
> `/device/<deviceID>/[from|to]/<cmd>`

The payload of the message will differ per command, but should always include
> `{ deviceID:<deviceID> }`

The following commands are supported:
### from (Device --> Server)
- register
- update* - Periodic per timer poll
- event* - Triggered by input interrupt
- state* - Response to config,read, and write
- alert* - Report system events?

### to (Server --> Device)
- config (was init) (response is state)
- read* - Request data from device (response is state)
- write* - Request state (response is state)

\* = not implemented yet

## Firmware
We need v1.5.4 from (https://nodemcu-build.com/) with the following modules:
- ADC
- bit (used?)
- CJSON
- DHT (used?)
- encoder (used?)
- file
- GPIO
- I2C (used?)
- MQTT
- net
- node
- 1-Wire (used?)
- PWM (used?)
- timer
- UART
- WIFI
- SSL support (used?)