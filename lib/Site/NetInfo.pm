#!/dev/null
########################################################################################################################
########################################################################################################################
##
##      Copyright (C) 2020 Peter Walsh, Milford, NH 03055
##      All Rights Reserved under the MIT license as outlined below.
##
##  FILE
##
##      Site::NetInfo.pm
##
##  DESCRIPTION
##
##      Return various network info structs
##
##  DATA
##
##      None.
##
##  FUNCTIONS
##
##      GetNetDevs()->[]    Return an array of network devices in the system
##
##      GetWPAInfo()->[]    Return array of WPA info
##          ->{SSID}            SSID of WiFi to connect
##          ->{KeyMgmt}         Key mgmt type
##          ->{Password}        Password to use with connection
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

package Site::NetInfo;
    use base "Exporter";

use strict;
use warnings;
use Carp;

use File::Slurp qw(read_file write_file);

our @EXPORT  = qw(&GetNetDevs
                  &GetWPAInfo
                  );          # Export by default

########################################################################################################################
########################################################################################################################
##
## Data declarations
##
########################################################################################################################
########################################################################################################################

our $DHCPConfigFile = "/etc/dhcpcd.conf";
our $WPAConfigFile  = "/etc/wpa_supplicant/wpa_supplicant.conf";

########################################################################################################################
########################################################################################################################
#
# GetNetDevs - Return list of network devices
#
# Inputs:   None.
#
# Outputs:  [Ref to] Array of network devices, by name
#
sub GetNetDevs {
    my $NetDevs = [];

    #
    # 1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    #     link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    # 2: eth0: <BROADCAST,MULTICAST> mtu 1500 qdisc mq state DOWN mode DEFAULT group default qlen 1000
    #     link/ether dc:a6:32:33:cd:91 brd ff:ff:ff:ff:ff:ff
    # 3: wlan0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP mode DORMANT group default qlen 1000
    #     link/ether dc:a6:32:33:cd:92 brd ff:ff:ff:ff:ff:ff
    #
    my @IPInfo = `ip link show`;
    chomp @IPInfo;

    foreach my $Line (@IPInfo) {
        next
            unless $Line !~ /^\s/;

        my ($Index,$Device,$Chuvmey) = split / /,$Line;

        substr($Device,-1) = ""
            if substr($Device,-1) eq ":";

        push @{$NetDevs},$Device;
        }

    return $NetDevs;
    }


########################################################################################################################
########################################################################################################################
#
# GetWPAInfo - Return wpa_supplicant info
#
# Inputs:   None.
#
# Outputs:  [Ref to] struct of WPA supplicant info
#
sub GetWPAInfo {
    my $WPAInfo = {};

    #
    # ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
    # update_config=1
    # country=US
    #
    # network={
    # 	ssid="netname"
    # 	psk="netpw"
    # 	key_mgmt=WPA-PSK
    #   }
    #
    $WPAInfo->{    SSID} = `grep ssid  m  $WPAConfigFile`;
    $WPAInfo->{Password} = `grep psk  m   $WPAConfigFile`;
    $WPAInfo->{ KeyMGMT} = `grep key_mgmt $WPAConfigFile`;
    
    $WPAInfo->{    SSID} =~ s/^.*ssid=\"(.+)\".*/$1/;
    $WPAInfo->{Password} =~ s/^.*psk=\"(.+)\".*/$1/;
    $WPAInfo->{ KeyMGMT} =~ s/^.*key_mgmt=(.+)\s/$1/;
    chomp $WPAInfo->{    SSID};
    chomp $WPAInfo->{Password};
    chomp $WPAInfo->{ KeyMGMT};

    return $WPAInfo;
    }


#
# Perl requires that a package file return a TRUE as a final value.
#
1;
