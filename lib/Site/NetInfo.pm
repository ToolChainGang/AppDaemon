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
##      GetNetEnable()->[]  Return array if enable/disable specifics from the netenable file
##          ->{Lines}           Lines from file, not concerning interface info
##          ->{$IF}             Points to interfaces entry for interface
##          ->{Interfaces}[]    List of interfaces seen
##
##      SetNetEnable($Info) Write new netenable info with new values
##
##      GetWPAInfo()->      Return array of WPA info
##          ->{Valid}           TRUE if WPA info file found
##          ->{SSID}            SSID of WiFi to connect
##          ->{KeyMgmt}         Key mgmt type         (ie: "WPA-PSK")
##          ->{Password}        Password to use with connection
##          ->{ Country}        Country code for Wifi (ie: "us")
##
##      SetWPAInfo($Info)   Write new WPA info with new values
##
##      GetDHCPInfo()->      Return array of interface specifics from DHCPCD.conf
##          ->{Lines}           Lines from file, not concerning interface info
##          ->{$IF}             Points to interfaces entry for interface
##          ->{Interfaces}[]    List of interfaces seen
##              ->{Name}            Name of interface (ie: "wlan0")
##              ->{Lines}[]         Lines specific to the interface (all of them)
##              ->{IPAddr}          Static IP address of interface
##              ->{Router}          Static router     of interface
##              ->{DNS1}            Static 1st DNS to use
##              ->{DNS2}            Static 2nd DNS to use
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
                  &GetNetEnable
                  &SetNetEnable
                  &GetWPAInfo
                  &SetWPAInfo
                  &GetDHCPInfo
                  &SetDHCPInfo
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
our $NEConfigFile   = "..//etc/netenable";

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

#use Data::Dumper;
#print Data::Dumper->Dump([$NetDevs],[qw(NetDevs)]);

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
    $WPAInfo->{ Country} = `grep country  $WPAConfigFile`;
    
    $WPAInfo->{    SSID} =~ s/^.*ssid=\"(.+)\".*/$1/;
    $WPAInfo->{Password} =~ s/^.*psk=\"(.+)\".*/$1/;
    $WPAInfo->{ KeyMGMT} =~ s/^.*key_mgmt=(.+)\s/$1/;
    $WPAInfo->{ Country} =~ s/^.*country=(.+)\s/$1/;
    chomp $WPAInfo->{    SSID};
    chomp $WPAInfo->{Password};
    chomp $WPAInfo->{ KeyMGMT};
    chomp $WPAInfo->{ Country};

    $WPAInfo->{Valid} = 0;
    $WPAInfo->{Valid} = 1
        if defined $WPAInfo->{SSID} and
           length  $WPAInfo->{SSID};

    return $WPAInfo;
    }


########################################################################################################################
########################################################################################################################
#
# SetWPAInfo - Write wpa_supplicant info
#
# Inputs:   [Ref to] struct of WPA supplicant info
#
# Outputs:  None.
#
# NOTE: This function sets a SINGLE set of wireless credentials, and uses the same method
#         as raspi-config. If your application needs multiple sets, then this method is
#         not appropriate.
#
sub SetWPAInfo {
    my $WPAInfo = shift;

    return
        unless $WPAInfo->{Valid};

my $wpa_text = <<"END_WPA";

ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=$WPAInfo->{Country}

network={
	ssid="$WPAInfo->{SSID}"
	psk="$WPAInfo->{Password}"
    key_mgmt=$WPAInfo->{KeyMGMT}
    }
END_WPA

#use Data::Dumper;
#print Data::Dumper->Dump([$WPAText],[qw(WPAText)]);

    write_file($WPAConfigFile,$wpa_text);
    }


########################################################################################################################
########################################################################################################################
#
# GetDHCPInfo - Return DHCPCD.conf information
#
# Inputs:   None.
#
# Outputs:  Hash of network data
#
sub GetDHCPInfo {
    my $State     = "START";
    my $Interface = "";

    my $DHCPInfo  = { Lines => [], Interfaces => [] };
    my @DHCPLines = eval{read_file($DHCPConfigFile)}    # Catches/avoids Croak() in lib function
        or return $DHCPInfo;

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
            push @{$DHCPInfo->{Interfaces}},{ Name => $IF, Lines => [] };
            push @{$DHCPInfo->{Interfaces}[-1]{Lines}},$Line;
            $DHCPInfo->{$IF} = $DHCPInfo->{Interfaces}[-1];
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

            push @{$DHCPInfo->{Interfaces}[-1]{Lines}},$Line;

            $DHCPInfo->{Interfaces}[-1]{IPAddr} = $1
                if $Line =~ /^\s*static\s*ip_address=(\d*\.\d*\.\d*\.\d*\/\d*)/;

            $DHCPInfo->{Interfaces}[-1]{Router} = $1
                if $Line =~ /^\s*static\s*routers=(\d*\.\d*\.\d*\.\d*)/;

            if( $Line =~ /^\s*static\s*domain_name_servers\s*=\s*(\d*\.\d*\.\d*\.\d*)\s*(\d*\.\d*\.\d*\.\d*)/ ) {
                $DHCPInfo->{Interfaces}[-1]{DNS1} = $1;
                $DHCPInfo->{Interfaces}[-1]{DNS2} = $2;
                }
            }
        }

    #
    # Ensure each device has an entry
    #
    my $NetDevs = GetNetDevs();
    foreach my $IF (@{$NetDevs}) {

        next
            unless defined $DHCPInfo->{$IF};

        push @{$DHCPInfo->{Interfaces}},{ Name => $IF, Lines => [], IPAddr => "", Router => "", DNS1 => "", DNS2 => "" };
        $DHCPInfo->{$IF} = $DHCPInfo->{Interfaces}[-1];
        }

#use Data::Dumper;
#print Data::Dumper->Dump([$DHCPInfo],[qw(DHCPInfo)]);

    return $DHCPInfo;
    }


########################################################################################################################
########################################################################################################################
#
# SetDHCPInfo - Set DHCPCD.conf information
#
# Inputs:   Hash of network data
#
# Outputs:  None.
#
sub SetDHCPInfo {
    my $DHCPInfo = shift;

    my $DHCPLines = [];

    #
    # Add out the initial lines (mostly comments, and some non-interface flags)
    #
    # Don't forget the EOLs
    #
    $DHCPLines = [ map { $_ . "\n" } @{$DHCPInfo->{Lines}} ];

    #
    # For each interface write out the new lines, but with changed information
    #
    foreach my $IF (@{$DHCPInfo->{Interfaces}}) {    
        #
        # Special case: If there are *no* lines associated with an interface, it's because
        #   there were none in the original DHCP file.
        #
        # If there's now a user-requested static config, then create an initial set of lines.
        #   This should filter unharmed through the loop below.
        #
        if( $IF->{Lines} == 0 and               # No existing lines for interface
            ( length($IF->{IPAddr}) or 
              length($IF->{Router}) or 
              length($IF->{  DNS1}) or 
              length($IF->{  DNS2}) ) ) {
            push @{$IF->{Lines}},"interface $IF->{Name}";
            push @{$IF->{Lines}},"    static ip_address=$IF->{IPAddr}";
            push @{$IF->{Lines}},"    static routers=$IF->{Router}";
            push @{$IF->{Lines}},"    static domain_name_servers=$IF->{DNS1} $IF->{DNS2}";
            push @{$IF->{Lines}},"";
            }

        #
        # Go through any existing lines the user may have, changing their configuration settings
        #   when encountered
        #
        for( my $LineNo = 0; $LineNo < @{$IF->{Lines}}; $LineNo++ ) {

            $IF->{Lines}[$LineNo] =~ s/$IF->{IPAddr}/$DHCPInfo->{IF}{IPAddr}/
                if $IF->{Lines}[$LineNo] =~ /ip_address/;

            $IF->{Lines}[$LineNo] =~ s/$IF->{Router}/$DHCPInfo->{IF}{Router}/
                if $IF->{Lines}[$LineNo] =~ /routers/;

            $IF->{Lines}[$LineNo] =~ s/$IF->{DNS1}/$DHCPInfo->{IF}{DNS1}/
                if $IF->{Lines}[$LineNo] =~ /domain_name_servers/;

            $IF->{Lines}[$LineNo] =~ s/$IF->{DNS2}/$DHCPInfo->{IF}{DNS2}/
                if $IF->{Lines}[$LineNo] =~ /domain_name_servers/;
            }

        #
        # Save the new settings. Don't forget linefeeds.
        #
        push @{$DHCPLines},map { $_ . "\n" } @{$IF->{Lines}};
        }

#use Data::Dumper;
#print Data::Dumper->Dump([$DHCPLines],[qw(DHCPInfo)]);

    write_file($WPAConfigFile,$DHCPLines);
    }


########################################################################################################################
########################################################################################################################
#
# GetNetEnable - Return parsed contents of netenable file
#
# Inputs:   None.
#
# Outputs:  Hash of network data
#
sub GetNetEnable {

    my $NEInfo  = { Lines => [], Interfaces => [] };
    my @NELines = eval{read_file($NEConfigFile)}    # Catches/avoids Croak() in lib function
        or return $NEInfo;

    foreach my $Line (@NELines) {

        chomp $Line;

        push @{$NEInfo->{Lines}},$Line;

        #
        # When an interface flag is seen, parse out the interface and flag
        #
        next
            unless $Line =~ '^(.*):\s*(enable|disable)';

        my $IF     = $1;            # (Set from previous match)
        my $Enable = $2;

        push @{$NEInfo->{Interfaces}},{ Name => $IF, Enabled => lc($Enable) eq "enable" ? 1 : 0};
        $NEInfo->{$IF} = $NEInfo->{Interfaces}[-1]->{Enabled};
        }

    #
    # Ensure each device has an entry
    #
    my $NetDevs = GetNetDevs();
    foreach my $IF (@{$NetDevs}) {

        next
            unless defined $NEInfo->{$IF};

        push @{$NEInfo->{Interfaces}},{ Name => $IF, Enabled => 1, lines => [ "$IF: enable" ]};
        $NEInfo->{$IF} = $NEInfo->{Interfaces}[-1];
        }

#use Data::Dumper;
#print Data::Dumper->Dump([$NEInfo],[qw(NEInfo)]);

    return $NEInfo;
    }


########################################################################################################################
########################################################################################################################
#
# SetNetEnable - Set enable flags for known interfaces
#
# Inputs:   Hash of enable data
#
# Outputs:  None.
#
sub SetNetEnable {
    my $EnbInfo  = shift;
    my $EnbLines = [];

    #
    # Add out the initial lines (mostly comments, and some non-interface flags)
    #
    # Don't forget the EOLs
    #
    foreach my $Line (@{$EnbInfo->{Lines}}) {
        foreach my $IF (@{$EnbInfo->{Interfaces}}) {
            $Line =~ s/enable|disable/$EnbInfo->{$IF}{Enabled} ? "enable" : "disable"/
                if $Line =~ '^(.*):\s*(enable|disable)';
            }

        push @{$EnbLines},$Line . "\n";
        }

#use Data::Dumper;
#print Data::Dumper->Dump([$NEInfo],[qw(NEInfo)]);

    write_file($NEConfigFile,$EnbLines);
    }



#
# Perl requires that a package file return a TRUE as a final value.
#
1;
