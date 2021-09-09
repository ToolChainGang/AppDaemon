#!/bin/bash
#
########################################################################################################################
########################################################################################################################
##
##      Copyright (C) 2020 Peter Walsh, Milford, NH 03055
##      All Rights Reserved under the MIT license as outlined below.
##
##  FILE
##      06-UpgradePerl.sh
##
##  DESCRIPTION
##      Do all the CPAN installs needed for perl programs
##
##      Mostly a lot of CPAN library installs
##
##  USAGE
##      06-UpgradePerl.sh
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
# The SaveCard program will add an additional 20 MB for proper booting. If the card with image has
#   more than 500MB of free space, we assume that the disk hasn't been expanded.
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
# Upgrade perl
#

#
# Set the CPAN defaults we need
#
# cpan> o conf prerequisites_policy 'follow'
# cpan> o conf build_requires_install_policy yes
# cpan> o conf commit
#
perl -MCPAN -e 'my $c = "CPAN::HandleConfig"; $c->load(doit => 1, autoconfig => 1); $c->edit(prerequisites_policy => "follow"); $c->edit(build_requires_install_policy => "yes"); $c->commit'

export PERL_CANARY_STABILITY_NOPROMPT=1

cpan Carp
cpan File::Basename
cpan File::Slurp
cpan JSON
cpan Net::WebSocket:Server
cpan RPi::Pin
cpan RPi::Const

########################################################################################################################
#
# All done - Tell the user to reboot
#
echo "========================="
echo
echo "Done with installation, reboot for changes to take effect."
echo
