#!/dev/null
#
########################################################################################################################
########################################################################################################################
##
##      Copyright (C) 2020 Peter Walsh, Milford, NH 03055
##      All Rights Reserved under the MIT license as outlined below.
##
##  FILE
##
##      Site::RasPiUtils.pm
##
##  DESCRIPTION
##
##      Various utility functions
##
##  DATA
##
##      None.
##
##  FUNCTIONS
##
##      Reboot()                # Reboot the system
##      IAmRoot()               # Return TRUE if user is running as root
##      NumUsers()              # Return number of logged-in users of the system
##      NumSSHUsers()           # Return number of SSH       users of the system
##      ListInterfaces()        # Return a list of interfaces on the system
##      DiskExpanded()          # Return TRUE if disk is expanded
##      ChangeHostname($Name)   # Change the hostname files
##
##  ISA
##
##      None.
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

package Site::RasPiUtils;
    use base "Exporter";

use strict;
use warnings;
use Carp;

our $VERSION = '2020.08_16';

our @EXPORT  = qw(&Reboot
                  &IAmRoot
                  &NumUsers
                  &NumSSHUsers
                  &ListInterfaces
                  &DiskExpanded
                  &ChangeHostname
                  );               # Export by default

########################################################################################################################
########################################################################################################################
##
## Reboot - Reboot the system
##
## Inputs:      None.
##
## Outputs:     None.
##
## NOTE: Function does not return!
##
sub Reboot {
    `reboot`;

    while(1) {};
    }


########################################################################################################################
########################################################################################################################
##
## IAmRoot - Return TRUE if caller is root
##
## Inputs:      None.
##
## Outputs:     TRUE  if caller is root
##              FALSE otherwise
##
sub IAmRoot {

    return $< == 0;
    }


########################################################################################################################
########################################################################################################################
##
## NumUsers - Return number of logged-in users of the system
##
## Inputs:      None.
##
## Outputs:     Numer of logged in users
##
sub NumUsers { return scalar split /\s/, `users`; }


########################################################################################################################
########################################################################################################################
##
## NumSSHUsers - Return number of SSH users of the system
##
## Inputs:      None.
##
## Outputs:     Numer of SSH logged in users
##
sub NumSSHUsers { return scalar, `ss | grep -i ssh`; }


########################################################################################################################
########################################################################################################################
##
## ListInterfaces - Grab the system interface list
##
## Inputs:      None.
##
## Outputs:     Array of interface listings: "wlan0", "wlan1", "eth0", "lo", and so on
##
## NB: There's a perl library for this, but it causes problems on the RasPi.
##
sub ListInterfaces {

    my @Interfaces = grep { /flags=/ } split /\n/, `ifconfig`;

    substr($_,index($_,":")) = ""
        foreach @Interfaces;

#    if( $Verbose ) {
#        Message("Iface: $_")
#            foreach @Interfaces;
#        }

    return @Interfaces;
    }


########################################################################################################################
########################################################################################################################
##
## DiskExpanded - Return TRUE if disk has been expanded
##
## Inputs:      None.
##
## Outputs:     TRUE  if disk is expanded
##              FALSE otherwise
##
sub DiskExpanded {
    `DiskExpanded`;

    return $? == 0;
    }


########################################################################################################################
########################################################################################################################
##
## ChangeHostname - Change system name, if requested
##
## Inputs:      New system name.
##
## Outputs:     None.
##
sub ChangeHostname {
    my $NEW_HOSTNAME = shift;

    die "Bad hostname $NEW_HOSTNAME"
        if $NEW_HOSTNAME !~ /^\w*$/;

    my $CURRENT_HOSTNAME = `cat /etc/hostname | tr -d " \t\n\r"`;

    if( $CURRENT_HOSTNAME eq $NEW_HOSTNAME ) {
##        print "Hostname unchanged ($CURRENT_HOSTNAME).\n";
        return;
        }

##    print "Changing hostname from $CURRENT_HOSTNAME to $NEW_HOSTNAME\n";

    `echo $NEW_HOSTNAME > /etc/hostname`;
    `chown root:root      /etc/hostname`;
    `chmod 644            /etc/hostname`;

    `sed -i "s/$CURRENT_HOSTNAME/$NEW_HOSTNAME/g" /etc/hosts`;
    `chown root:root /etc/hosts`;
    `chmod 644       /etc/hosts`;
    }



#
# Perl requires that a package file return a TRUE as a final value.
#
1;
