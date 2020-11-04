#!/dev/null
########################################################################################################################
########################################################################################################################
##
##      Copyright (C) 2020 Peter Walsh, Milford, NH 03055
##      All Rights Reserved under the MIT license as outlined below.
##
##  FILE
##
##      Site::FSInfo.pm
##
##  DESCRIPTION
##
##      Return various file sharing (ie - Samba) information
##
##  DATA
##
##      None.
##
##  FUNCTIONS
##
##      GetFSInfo()         Return array of sharing info
##          ->{Valid}           TRUE if smb.conf found
##          ->{Workgroup}       Samba workgroup
##          ->{Users}           Samba users  
##              ->{UserName}    Specific Samba user
##
##      SetFSInfo($Info)    Write new FS info with new values
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

package Site::FSInfo;
    use base "Exporter";

use strict;
use warnings;
use Carp;

use File::Slurp qw(read_file write_file);

use Site::ParseData;

our @EXPORT  = qw(&GetFSInfo
                  &SetFSInfo
                  );          # Export by default

########################################################################################################################
########################################################################################################################
##
## Data declarations
##
########################################################################################################################
########################################################################################################################

our $FSConfigFile = "/etc/samba/smb.conf";

#
#   workgroup = WORKGROUP
#
our $FSMatches = [
    {                      RegEx => qr/^\s*#/                   , Action => Site::ParseData::SkipLine }, # Skip comments
    {                      RegEx => qr/^\s*;/                   , Action => Site::ParseData::SkipLine }, # Skip comments
    { Name => "Workgroup", RegEx => qr/^\s*workgroup\s*=\s*(.+)/, Action => Site::ParseData::AddVar   },
    ];

########################################################################################################################
########################################################################################################################
#
# GetFSInfo - Return smb.conf info
#
# Inputs:   None.
#
# Outputs:  [Ref to] struct of FS supplicant info
#
sub GetFSInfo {

    return { Valid => 0 }
        unless -r $FSConfigFile;

    my $ConfigFile = Site::ParseData->new(Filename => $FSConfigFile, Matches  => $FSMatches);

    my $FSInfo = $ConfigFile->Parse();

    $FSInfo->{Valid} = 1;

    return $FSInfo;
    }


########################################################################################################################
########################################################################################################################
#
# SetFSInfo - Write smb.conf info
#
# Inputs:   [Ref to] struct of WPA supplicant info
#
# Outputs:  None.
#
sub SetFSInfo {
    my $FSInfo = shift;

    #
    # If the original file did not exist, we simply punt. It probably means samba is not installed.
    #
    return
        unless -r $FSConfigFile;
    
    my $ConfigFile = Site::ParseData->new(Filename => $FSConfigFile, Matches => $FSMatches);
    $ConfigFile->Parse();

    #
    # Update the existing workgroup
    #
    $ConfigFile->{Sections}{Global}{Workgroup}{NewValue} = $FSInfo->{Workgroup};

    $ConfigFile->Update();

# use Data::Dumper;
# print Data::Dumper->Dump([$ConfigFile->{Lines}],[$ConfigFile->{Filename}]);

    }



#
# Perl requires that a package file return a TRUE as a final value.
#
1;
