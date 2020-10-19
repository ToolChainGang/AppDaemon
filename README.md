# AppDaemon
Config daemon and application monitor for Raspberry Pi systems

This is a daemon that monitors user applications. The intent is for a high-reliability system where
one process is doing something which might hang, crash, or otherwise become a problem. When a
problem with the application is detected, this daemon will reboot the system and presumably reset
the system.

Additionally, for RasPi systems this demon can monitor a GPIO input as button press. When pressed,
the system switches to AP mode, and connecting to that AP shows a web page that allows a user to
configure the system. In this way, an end-user can install and configure the device using a cell
phone or other net enabled computer without technical expertise.


