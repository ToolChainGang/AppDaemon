# AppDaemon: Easy end-user configuration for RasPi systems

## Installing

This is an application-level program, not a system command or system feature. It is an add-on to your
product software, and as such there is no global "apt-get install". You will need a copy of the source
to modify for your needs.

### Step 1: Copy the project to the /root directory.

```
> sudo su
> cd /root
> git clone https://github.com/ToolChainGang/AppDaemon.git
```

### Step 2: Upgrade your system 

The project subdir "install" contains scripts to upgrade your system and install needed packages.

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

### Step 3: Test your GPIO hardware

The install directory contains a GPIO testing app using the same logic as the AppDaemon.

Execute that app with your GPIO settings and verify that the config button hardware works,
your LED blinks (if you use a config LED), and so on.

For example:

```
> GPIOTest --config-gpio=4 --led-gpio=19
```

### Step 4: Install the test application

The install directory contains a sample application (SampleApp) for testing.

Copy that app to the /home/pi directory, change the owner to pi:pi, then add a line to your
/etc/rc.local file that invokes the AppDaemon with that file.

For example, put this in your /etc/rc.local file:

```
########################################################################################################################
#
# Start the AppDaemon
#
set +e

ConfigGPIO=4;       # Config switch WPi07, Connector pin  7, GPIO (command) BCM 04
LEDGPIO=19;         # Config LED    WPi24, Connector pin 35, GPIO (command) BCM 19

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

### Step 5: Connect the AppDaemon to your application

Once everything is running the /root/AppDaemon/install directory is no longer needed - you can delete it.

Change the link in rc.local to run your application instead of the SampleApp, and you're good to go.
