# AppDaemon: Easy end-user configuration for RasPi systems

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


