#!/dev/null
########################################################################################################################
########################################################################################################################
##
##      Copyright (C) 2016 Rajstennaj Barrabas, Milford, NH 03055
##      All Rights Reserved under the MIT license as outlined below.
##
##  FILE
##      Site::IWList.pm
##
##  DESCRIPTION
##      IWList parsing
##
##  DATA
##
##      None.
##
##  FUNCTIONS
##
##      $List = GetIWList()     # Return parsed IWList
##      
##      Where:
##
##          $List->{wlan0} => []
##                 {wlan1} => []
##                    :       :
##
##      Each array element is one SSID seen by the interface
##
##             ->[2]->{Addr}       = '1A:05:01:D8:09:68'
##             ->[2]->{Channel}    = 6
##             ->[2]->{Encryption} = 'off'
##             ->[2]->{Mode}       = 'Master'
##             ->[2]->{Quality}    = '35/70'
##             ->[2]->{QualityPct} = 0.5
##             ->[2]->{SSID}       = 'xfinitywifi'
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

package Site::IWList;
    use base "Exporter";

use strict;
use warnings;
use Carp;

our @EXPORT  = qw(&GetIWList);

########################################################################################################################
########################################################################################################################
##
## Data declarations
##
########################################################################################################################
########################################################################################################################

########################################################################################################################
########################################################################################################################
#
# GetIWList - Return list of network connections
#
# Inputs:   None.
#
# Outputs:  Hash of network data
#
sub GetIWList {

    my $List;

    my $State = "START";
    my $CN    = 0;
    my $IF    = "";

    $List = {};

    my @IWListLines = `iwlist scan 2>/dev/null`;

    foreach my $Line (@IWListLines) {

        chomp $Line;

        if( length $Line == 0 ) {
            $State = "START";
            next;
            }

        ################################################################################################################
        #
        # START: Look for an initial interface line
        #
        #       wlan1     Scan completed :
        #
        if( $State eq "START" ) {
            unless( $Line =~ "Scan completed" ) {
                print "IWLIST[START]: Ignoring line $Line\n";
                next;
                }

            my ($IF1,$unused) = split /\s/,$Line;

            $IF    = $IF1;
            $List->{$IF} = [];
            $State = "IF";
#print "Interface: $IF\n";
            next;
            }

        ################################################################################################################
        #
        # IF: Look for "cell" line
        #
        #       wlan1     Scan completed :
        #       Cell 07 - Address: 1E:05:01:D8:09:68
        #
        if( $State eq "IF" ) {

            if( $Line =~ "Cell" && $Line =~ "Address" ) {
                $Line =~ /Cell\s+(\d+)\s-\sAddress: (.+)/;
                $CN    = $1-1;
                $List->{$IF}[$CN]{Addr} = $2;
                $State = "CELL";
#print "  Cell: $CN\n";
                next;
                }

            if( $Line =~ "Scan completed" ) {
                my ($IF1,$unused) = split /\s/,$Line;

                $IF    = $IF1;
                $List->{$IF} = [];
                $State = "IF";
#print "Interface: $IF\n";
                next;
                }

            print "IWLIST[IF]: Ignoring line $Line\n";
            next;
            }


        ################################################################################################################
        #
        # CELL: Look for "cell" line
        #
        #         Channel:11
        #         Frequency:2.462 GHz (Channel 11)
        #         Quality=57/70  Signal level=-53 dBm  
        #         Encryption key:on
        #         ESSID:"Okima"
        #         Bit Rates:1 Mb/s; 2 Mb/s; 5.5 Mb/s; 11 Mb/s; 22 Mb/s
        #                   6 Mb/s; 9 Mb/s; 12 Mb/s
        #         Bit Rates:18 Mb/s; 24 Mb/s; 36 Mb/s; 48 Mb/s; 54 Mb/s
        #         Mode:Master
        #         Extra:tsf=0000038d3130046f
        #         Extra: Last beacon: 18690ms ago
        #         IE: Unknown: 00054F6B696D61
        #
        if( $State eq "CELL" ) {

            if( $Line =~ "Scan completed" ) {
                my ($IF1,$unused) = split /\s/,$Line;

                $IF    = $IF1;
                $List->{$IF} = [];
                $State = "IF";
#print "Interface: $IF\n";
                next;
                }

            if( $Line =~ "Cell" && $Line =~ "Address" ) {
                $Line =~ /Cell\s+(\d+)\s-\sAddress: (.+)/;
                $CN    = $1-1;
                $List->{$IF}[$CN]{Addr} = $2;
                $State = "CELL";
#print "  Cell: $CN\n";
                next;
                }

            if( $Line =~ "IE: Unknown" ||
                $Line =~ "Extra:"      ||
                $Line =~ "Frequency"   ||
                $Line =~ "Bit Rates:"  ) {
                next;
                }

            if( $Line =~ "Channel" ) {
                $Line =~ /Channel:(\d+)/;
                $List->{$IF}[$CN]{Channel} = $1;
#print "     Channel: $List->{$IF}[$CN]{Channel}\n";
                next;
                }

            if( $Line =~ "Quality" ) {
                $Line =~ /Quality=(\d+\/\d+)/;
                $List->{$IF}[$CN]{Quality} = $1;
                my ($Qual1,$Qual2) = split "/",$1;
                $List->{$IF}[$CN]{QualityPct} = ($Qual1 // 0)/($Qual2 // 1);
#print "     Quality: $List->{$IF}[$CN]{Quality}\n";
                next;
                }

            if( $Line =~ "Encryption key" ) {
                $Line =~ /Encryption key:(..)$/;
                $List->{$IF}[$CN]{Encryption} = $1 // "off";
#print "     Encryption: $List->{$IF}[$CN]{Encryption}\n";
                next;
                }

            if( $Line =~ "ESSID" ) {
                $Line =~ /ESSID:"(.+)"$/;
                $List->{$IF}[$CN]{SSID} = $1 // "--none--";
#print "     SSID: $List->{$IF}[$CN]{SSID}\n";
                next;
                }

            if( $Line =~ "Mode" ) {
                $Line =~ /Mode:(.+)$/;
                $List->{$IF}[$CN]{Mode} = $1;
#print "     Mode: $List->{$IF}[$CN]{Mode}\n";
                next;
                }

#            print "IWLIST[CELL]: Ignoring line $Line\n";
            next;
            }
        }

    #
    # Sort the SSID by QualityPct before returning.
    #
    foreach $IF (keys %{$List}) {
        @{$List->{$IF}} = sort { $b->{QualityPct} <=> $a->{QualityPct} } @{$List->{$IF}};
        }

    return $List;
    }



#
# Perl requires that a package file return a TRUE as a final value.
#
1;
