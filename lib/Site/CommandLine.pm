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
##      Site::CommandLine.pm      Parse command line options
##
##  DESCRIPTION
##
##      A standardized plug of code to parse command line options.
##
##      Automatically implements --help and --version options, and uses the executable file
##        header information as help text.
##
##  DATA
##
##      None.
##
##  FUNCTIONS
##
##      ParseCommandLine(\%Args,$ArgFlags)  # Parse flags into %Args var
##      ParseCommandLine($ArgFlags)         # Parse flags into individual vars
##
##      HELP_MESSAGE()                      # Print help    message
##      VERSION_MESSAGE()                   # Print version message
##
##      $File = GetInputFile()              # Return next arg as input  file
##      $File = GetOutputFile()             # Return next arg as output file
##
##  ISA
##
##      None.
##
##  NOTES
##
##      Typical usage:
##
##          ParseCommandLine(       "a|aoption" => \$AOption,"b|boption" => \$BOption, ...);
##          ParseCommandLine(\%Args,"a|aoption"             , "b|boption"            , ...);
##
##      "verbose"   => \$verbose            # Sets var if flag encountered
##      "verbose+"  => \$verbose            # Incs var each time flag encountered
##      "verbose!"  => \$verbose            # Allows "verbose" and "noverbose"
##
##      "file=s"    => \$file               # String  value
##      "file:s"    => \$file               # String  value optional (=> "" if unspecified)
##      "length=i"  => \$length             # Numeric value
##      "avg=f"     => \$avg                # Float   value
##      "avg:f"     => \$avg                # Float   value optional (=> 0 if unspecified)
##
##      "length|height=f" => \$length       # Synonyms for same flag
##
##      "library=s" => \@libfiles           # Multiple flags with multiple values
##      "library=s@" => \$libfiles          # Same, with ref output
##      "rgbcolor=i{3}" => \@color          # Multiple values for 1 flag
##
##      "define=s"  => \%defines            # Multiple flags, hash output
##      "define=s%" => \$defines            # Same, with ref output
##
##      "quiet"     => sub { ... }          # Call sub when flag seen
##      "opt=i"     => \&handler)           # Same, with ref
##
##          sub handler {
##              my ($opt_name, $opt_value) = @_;
##                  :       :
##              }
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

package Site::CommandLine;
    use base "Exporter";

use strict;
use warnings;
use Carp;

use Getopt::Long qw(:config no_ignore_case);
use FindBin      qw($Bin $RealScript);
use File::Slurp;
use File::Basename;

our $VERSION = '2020.08_16';

our @EXPORT  = qw(&ParseCommandLine
                  &GetInputFile
                  &GetOutputFile
                  &HELP_MESSAGE
                  &VERSION_MESSAGE);            # Export by default

########################################################################################################################
########################################################################################################################
#
# ParseCommandLine - Parse the program command line, using Getopt::Long
#
# Inputs:   [Ref to] %Args var for results
#           String of Getopt::Long parameters to include
#
# Outputs:  None.
#
# NOTE:     Prints help message and calls exit() if command args can't be parsed.
#
sub ParseCommandLine {

#    print "Args: $_\n"
#        foreach @ARGV;

    if( defined $_[0] and ref $_[0] eq "HASH" ) {
        my $Args = shift;

        exit HELP_MESSAGE()
            unless GetOptions($Args,"h|help","version",@_);

        exit HELP_MESSAGE()
            if $Args->{h};

        exit VERSION_MESSAGE()
            if $Args->{v};
        }
    else {
        my $Help = 0;
        my $Vers = 0;

        exit HELP_MESSAGE()
            unless GetOptions("h|help" => \$Help,"version" => \$Vers, @_);

        exit HELP_MESSAGE()
            if $Help;

        exit VERSION_MESSAGE()
            if $Vers;
        }
    }


########################################################################################################################
########################################################################################################################
#
# GetInputFile - Return command line arg filename for input
#
# Inputs:   None.
#
# Outputs:  Input file command line argument
#
# NOTE:     File must be entered on command line, exist, and be readable. Otherwise an error is printed.
#
sub GetInputFile {

    my $InputFile = shift @ARGV;

    unless( defined $InputFile ) {
        print "\n*** $RealScript: No input file specified.\n";
        exit HELP_MESSAGE();
        }

    die "$InputFile: Not readable"
        unless -e $InputFile;

    return $InputFile;
    }


########################################################################################################################
########################################################################################################################
#
# GetOutputFile - Return command line arg filename for output
#
# Inputs:   None.
#
# Outputs:  Output file command line argument
#
# NOTE:     File must be entered on command line, exist, and be writable. Otherwise an error is printed.
#
sub GetOutputFile {

    my $OutputFile = shift @ARGV;

    unless( defined $OutputFile ) {
        print "\n*** $RealScript: No output file specified.\n";
        exit HELP_MESSAGE();
        }

    die "$OutputFile: Not readable"
        unless -e $OutputFile;

    return $OutputFile;
    }


########################################################################################################################
########################################################################################################################
#
# HELP_MESSAGE - Print out help information
#
# Inputs:   None.
#
# Outputs:  Zero
#
sub HELP_MESSAGE {

    #
    # Print the text in the preamble of the script (at the top of the main file) 
    #   for the help message.
    #
    my @Usage = read_file("$Bin/$RealScript");

    shift @Usage
        until $Usage[0] =~ /USAGE/;

    shift @Usage;           # Skip USAGE line

    #
    # Print everything between the "Usage" line and the subsequent "Example" line.
    #   If no "Example" line is found, terminate at the comment barrier.
    #
    print "\n";
    print "Usage: ";
    while(1) {
        my $Line = shift @Usage;

        last
            if $Line =~ /EXAMPLE/;

        last
            if $Line =~ /###/;

        $Line =~ s/\#\#//;

        print $Line;
        }

    return 0;
    }

########################################################################################################################
########################################################################################################################
#
# VERSION_MESSAGE - Print out current module version
#
# Inputs:   None.
#
# Outputs:  Zero.
#
sub VERSION_MESSAGE {

    #
    # Print the text in the preamble of the script (at the top of the main file) 
    #   for the help message.
    #
    # By rights, the version definition should be the first line that matches
    #
    my @VersionLines = grep { $_ =~ /\$VERSION/; } read_file("$Bin/$RealScript");

    my $Version = $VersionLines[0] // "Unknown";

    #
    # Strip the perl syntax for better looking output
    #
    $Version =~ s/.* = //;
    $Version =~ s/;.*//;
    $Version =~ s/\'//g;
    $Version =~ s/\"//g;

    print "\n";
    print basename($0) . " version $Version\n";

    return 0;
    }


#
# Perl requires that a package file return a TRUE as a final value.
#
1;
