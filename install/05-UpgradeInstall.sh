#!/bin/bash
#
########################################################################################################################
########################################################################################################################
##
##      Copyright (C) 2020 Peter Walsh, Milford, NH 03055
##      All Rights Reserved under the MIT license as outlined below.
##
##  FILE
##      05-UpgradeInstall.sh
##
##  DESCRIPTION
##      Do all the system (ie: non-perl) upgrades and installs needed for the AppDaemon
##
##  USAGE
##      05-UpgradeInstall.sh
##
##  NOTES
##      Wifi access can be intermittant, causing some installs to fail. This will leave the system
##        in a *valid* state, with some packages downloaded but not installed.
##
##      The recommended procedure is to run this script over and over until the output consists  
##        exclusively of "already the newest version" messages and the like.
##
########################################################################################################################
########################################################################################################################
##
##  MIT LICENSE
##
##  Permission is hereby granted, free of charge, to any person obtaining a copy of
##    this software and associated documentation files (the "Software"), to deal in
##    the Software without restriction, including without limitation the rights to
##    use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
##    of the Software, and to permit persons to whom the Software is furnished to do
##    so, subject to the following conditions:
##
##  The above copyright notice and this permission notice shall be included in
##    all copies or substantial portions of the Software.
##
##  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
##    INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
##    PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
##    HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
##    OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
##    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
##
########################################################################################################################
########################################################################################################################

PATH="$PATH:$HOME/AppDaemon/bin"

########################################################################################################################
########################################################################################################################
#
# Ensure we're being run as root
#
if [ "$EUID" -ne 0 ]; then
    echo
    echo "Must be run as root" 
    echo
    exit 1
    fi

########################################################################################################################
########################################################################################################################
#
# Ensure that the disk has been expanded
#
DiskSize="$(lsblk  -b /dev/mmcblk0   | grep disk | awk '{print $4}')"
Part1Size="$(lsblk -b /dev/mmcblk0p1 | tail -n1  | awk '{print $4}')"
Part2Size="$(lsblk -b /dev/mmcblk0p2 | tail -n1  | awk '{print $4}')"
Unused=$(($DiskSize-$Part1Size-$Part2Size))

#  echo "Disk  : $DiskSize"
#  echo "Part1 : $Part1Size"
#  echo "Part2 : $Part2Size"
#  echo "Unused: $Unused"

########################################################################################################################
#
# The SaveCard program will add an additional 20 MB for proper booting. If the resulting image
#   has less than 500MB of free space, we assume that the disk hasn't been expanded.
#
if [ "$Unused" -gt 500000000 ]; then
    echo "============>Disk is not expanded. Expand the disk, reboot, and rerun this script."
    echo
    echo "Expand command: raspi-config --expand-rootfs"
    echo
    exit
    fi

########################################################################################################################
########################################################################################################################
#
# Upgrade linux installation
#
echo "========================="
echo "Upgrading linux"

apt-get update
apt-get -y upgrade

echo "Done."
echo

########################################################################################################################
########################################################################################################################
#
# Packages
#
echo "===================================="
echo "Installing packages"

apt-get -y install samba samba-common-bin smbclient
apt-get -y install dnsmasq hostapd
apt-get -y autoremove

#
# Upgrade WiringPi, in case RasPi v4
#
cd /tmp
wget https://project-downloads.drogon.net/wiringpi-latest.deb
sudo dpkg -i wiringpi-latest.deb

echo "Done."
echo

########################################################################################################################
#
# All done - Tell the user to reboot
#
echo "========================="
echo
echo "Done with installation, reboot for changes to take effect."
echo
