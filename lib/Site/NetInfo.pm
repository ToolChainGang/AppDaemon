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
##      GetNetDevs()->[]    Return an array of network device names in the system (ie: [0]->"wlan0" )
##
##      GetWPAInfo()->      Return array of WPA info
##          ->{SSID}            SSID of WiFi to connect
##          ->{KeyMgmt}         Key mgmt type
##          ->{Password}        Password to use with connection
##
##      SetDHCPInfo()->      Return array of interface specifics from DHCPCD.conf
##          ->{Lines}           Lines from file, not concerning interface info
##          ->{IF}              Lines specific to one interface
##          ->{IF}{Lines}           Lines specific to the interface (all of them)
##          ->{IF}{IPAddr}          Static IP address of interface
##          ->{IF}{Router}          Static router     of interface
##          ->{IF}{DNS1}            Static 1st DNS to use
##          ->{IF}{DNS2}            Static 2nd DNS to use
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
                  &GetDHCPInfo
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
# NOTE: This function can recognize a SINGLE set of credentials on a system. This is
#         consistent with Raspbian initial config using raspi-config. If your application
#         uses multiple sets of Wifi credentials, this functiln will fail.
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
    $WPAInfo->{    SSID} = `grep ssid     $WPAConfigFile`;
    $WPAInfo->{Password} = `grep psk      $WPAConfigFile`;
    $WPAInfo->{ KeyMGMT} = `grep key_mgmt $WPAConfigFile`;
    
    $WPAInfo->{    SSID} =~ s/^.*ssid=\"(.+)\".*/$1/;
    $WPAInfo->{Password} =~ s/^.*psk=\"(.+)\".*/$1/;
    $WPAInfo->{ KeyMGMT} =~ s/^.*key_mgmt=(.+)\s/$1/;
    chomp $WPAInfo->{    SSID};
    chomp $WPAInfo->{Password};
    chomp $WPAInfo->{ KeyMGMT};

    return $WPAInfo;
    }


########################################################################################################################
########################################################################################################################
#
# GetDHCPCD - Return DHCPCD information
#
# Inputs:   None.
#
# Outputs:  Hash of network data
#
sub GetDHCPInfo {
    my $State     = "START";
    my $Interface = "";

    my $DHCPInfo  = { Lines => [] };

    my @DHCPLines = eval{read_file($DHCPConfigFile)}    # Catches/avoids Croak() in lib function
        or die "GetDHCPInfo: Cannot read $DHCPConfigFile ($!)";

    foreach my $Line (@DHCPLines) {

        chomp $Line;

        ################################################################################################################
        #
        # START: Look for an initial interface line
        #
        #       interface wlan0
        #
        if( $State eq "START" ) {

            #
            # Anything that's not an interface block is considered a generic "line", and goes
            #   in the generic section.
            #
            unless( $Line =~ "^interface" ) {
                push @{$DHCPInfo->{Lines}},$Line;
#print "DHCPInfo[START]: Ignoring line $Line\n";
                next;
                }

            #
            # When "interface" is seen, grab the name and switch to the interface parser
            #
            my ($Unused,$IF) = split /\s/,$Line;

            $Interface = $IF;
            $DHCPInfo->{$Interface} = {};
            push @{$DHCPInfo->{$Interface}{Lines}},$Line;
            $State = "IF";
#print "DHCPInfo[START]: Interface $IF\n";
            next;
            }

        ################################################################################################################
        #
        # IF: Look for interface config lines
        #
        #   interface wlan0
        #       static ip_address=192.168.1.31
        #       static routers=192.168.1.1
        #       static domain_name_servers=1.1.1.1 1.0.0.1
        #
        if( $State eq "IF" ) {

            #
            # When another block begins, start a new device section
            #
            redo
                if $Line =~ "interface";

#print "DHCPInfo[IF]: $Line\n";

            push @{$DHCPInfo->{$Interface}{Lines}},$Line;

            $DHCPInfo->{$Interface}{IPAddr} = $1
                if $Line =~ /^\s*static\s*ip_address=(\d*\.\d*\.\d*\.\d*\/\d*)/;

            $DHCPInfo->{$Interface}{Router} = $1
                if $Line =~ /^\s*static\s*routers=(\d*\.\d*\.\d*\.\d*)/;

            if( $Line =~ /^\s*static\s*domain_name_servers=(\d*\.\d*\.\d*\.\d*)\s*(\d*\.\d*\.\d*\.\d*)/ ) {
                $DHCPInfo->{$Interface}{DNS1} = $1;
                $DHCPInfo->{$Interface}{DNS2} = $2;
                }
            }
        }

    return $DHCPInfo;
    }



#
# Perl requires that a package file return a TRUE as a final value.
#
1;
