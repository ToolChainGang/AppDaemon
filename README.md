# AppDaemon: Easy end-user configuration for RasPi systems

<table>
<tbody>
<tr><td style="width: 50%">
How does an end-user configure a RasPi product?

Specifically, if you have a product with an embedded RasPi, how does the user:
- Enter their WiFi password?
- Connect to their filesharing workgroup?
- Set a fixed IP address?
- Disable Wifi and use ethernet?
- Choose a name for their system?

Attaching a display and keyboard is a bother, and end users
might not have a spare display and keyboard laying around.

This project supplies a way for the end-user to easily configure a RasPi system.

</td>
<td><img style="float: right; margin: 0px 0px 10px 10px;" class="lazy" src="https://cdn.hackaday.io/images/1857511605398555259.png">
</td>
</tr></tbody></table>

## How it works

The AppDaemon runs your application (your product software) at system boot. If your application crashes or hangs,
the daemon will automatically reboot the system.

The "AppDaemon" application also monitors a GPIO button. When pressed, the system will stop running your application
and switch to Access Point mode. It will broadcast an access point with the name of the system, when connected to
that AP the user is presented with a configuration panel to set system parameters such as their home WiFi and password.

When the user saves the configuration, the system will reboot and continue your product application.

## Monitoring the product application

The AppDaemon is given an application to run, and will monitor that application for correct execution. If the
application crashes, hangs, or exits the AppDaemon reboot the system and rerun the application.

The intent is for a high-reliability system where one process is doing something which might hang, crash,
or otherwise become a problem. When a problem with the application is detected, this daemon will reboot and
presumably clear the error.

(This program was originally made to monitor cell modem applications, where the cell modem can crash or hang or
be unusable for myriad reasons, and sometimes even detecting that a problem exists is impossible.)

## Installing

Installation instructions are in the file "INSTALL.md" supplied with the project.