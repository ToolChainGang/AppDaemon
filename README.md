# AppDaemon: Easy end-user configuration for RasPi systems

How does an end-user configure a RasPi product?

Specifically, if you have a product with an embedded RasPi, how does the user:
- Enter their WiFi password?
- Connect to their filesharing workgroup?
- Set a fixed IP address?
- Disable Wifi and use ethernet?
- Choose a name for their system?

Attaching a display and keyboard is a bother, and end users might not have a spare display and keyboard laying around.

This project supplies a way for the end-user to easily configure a RasPi system.

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

This is an application-level program, not a system command or system feature. It is an add-on to your
product software, and as such there is no global "apt-get install". You will need a copy of the source
to modify it to your needs.

### Step 1: Copy the project to the /root directory.

```
> sudo su
> cd /root
> git clone https://github.com/ToolChainGang/AppDaemon.git
```

### Step 2: Upgrade your system 

The project subdir "install" contains scripts to upgrade your system and install any needed packages.

For proper installation, each script should be run multiple times, fixing errors as needed until the
output contains nothing but a list of "already have most recent version" messages.

```
(as root)

> cd /root/AppDaemon/install
> ./05-UpgradeInstall.sh

Go get lunch, then rerun the script

> ./05-UpgradeInstall.sh

Verify that the output contains nothing but a list of "newest version" messages.

> ./05-UpgradePerl.sh

Go get dinner, then rerun the script

> ./05-UpgradePerl.sh

Verify that the output contains nothing but a list of "newest version" messages.

```

### Step 3: Install the test application

The install dir contains a sample application (SampleApp) that can be used to test the system.

Copy that app to the /home/pi directory, then add a line to your /etc/rc.local file that invokes
the AppDaemon with that file.

For example, put this in your /etc/rc.local file:

```
########################################################################################################################
#
# Start the AppDaemon
#
set +e

ConfigGPIO = 22;        # Config switch GPIO22, Connector pin 15, GPIO (command) BCM 22
LEDGPIO    = 21;        # Config LED    GPIO21, Connector pin 40, GPIO (command) BCM 21

#nohup /root/AppDaemon/bin/AppDaemon   --config-gpio=$ConfigGPIO --led-gpio=$LEDGPIO --user=pi /home/pi/SampleApp &
nohup /root/AppDaemon/bin/AppDaemon -v --config-gpio=$ConfigGPIO --led-gpio=$LEDGPIO --user=pi /home/pi/SampleApp &

set -e
```

A sample rc.local file that does this is included with the project, so for a quick test you can do the following:

```
(as root) 

> cd /root/AppDaemon/install
> cp SampleApp /home/pi/
> chown pi:pi /home/pi/SampleApp
> cp /etc/rc.local /etc/rc.local.bak
> cp rc.local.SAMPLE /etc/rc.local
> reboot
```

### Step 4: Connect the AppDaemon to your application

Once everything is running the /root/AppDaemon/install directory is no longer needed - you can delete it.

Change the link in rc.local to run your application instead of the SampleApp, and you're good to go.


