#!/dev/null
########################################################################################################################
########################################################################################################################
##
##      Copyright (C) 2020 Peter Walsh, Milford, NH 03055
##      All Rights Reserved under the MIT license as outlined below.
##
##  FILE
##
##      Site::ParseData.pm
##
##  DESCRIPTION
##
##      Parse config file (or other) data, and optionally change certain sections
##
##  DATA
##
##      ->{Filename}                    File of config info we parsed
##      ->{Lines}[]                     Array of lines read from file
##      ->{Matches}                     Matches to look for in file
##      ->{Sections}                    Hash of sections by name
##          ->{$SecName}
##              ->{LineNo}              Line number of section starter
##              ->{$Var}                Variables found in section
##                  ->{Value}           Value of variable
##                  ->{LineNo}          Line # where value was found
##                  ->{NewValue}        New value to set during update call
##      ->{AsHash}                      Pure hash version of section data
##          ->{$Section}                Named section
##              ->{$Var}=>$Value        Value of variable in section
##
##  FUNCTIONS
##
##      ->new(%Args)                    Make a new parser with specified params
##          Filename => $Filename       Name of file to parse
##          Matches  => []              List of actions to take when parsing file
##              ->{RegEx}               Regular expression to match
##              ->{Action}              One of the actions listed below
##              ->{Name}                Optional name, used in command
##
##      ->Parse($Filename)              Parse specified file
##      ->Parse(\@Lines)                Parse specified lines
##
##      ->AddLines($Line,@Lines...)     Add more lines to file
##      ->Comment($Section,$Comment)    Comment out a section
##
##      ->Update($Filename)             Update specified file with new data
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

package Site::ParseData;

use strict;
use warnings;
use Carp;

use File::Slurp qw(read_file write_file);

########################################################################################################################
########################################################################################################################
##
## Data declarations
##
########################################################################################################################
########################################################################################################################

use constant StartSection   => 0;
use constant EndSection     => 1;
use constant AddVar         => 2;
use constant AddGlobal      => 3;
use constant SkipLine       => 4;

use constant CommentHash    => 1;       # Commented by prepending hash

our $GLOBAL_SECTION = "Global";

########################################################################################################################
########################################################################################################################
#
# Site::ConfigFile - Parse a config file
#
# Inputs:   List of action to take while parsing
#
# Outputs:  Parsed config info
#
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $Args  = { @_ };
    my $self  = bless $Args,$class;

    $self->{  AsHash} = {};
    $self->{   Lines} = [];
    $self->{Sections}{$GLOBAL_SECTION} = {};

    return $self;
    }


########################################################################################################################
########################################################################################################################
#
# Parse - Parse a config file
#
# Inputs:   Filename to parse (default: uses internal filename)
#           ALTERNATE: Array of lines to parse
#
# Outputs:  TRUE  if file parsed correctly
#           FALSE if an error occurred (check $! for more info)
#
sub Parse {
    my $self     = shift;
    my $Filename = shift // $self->{Filename};

    if( ref($Filename) eq "ARRAY" ) {
        $self->{Filename} = undef;
        $self->{Lines}    = [ @{$Filename} ];
        }
    else {
        $self->{Filename} = $Filename;
        @{$self->{Lines}} = eval{read_file($Filename)}      # Catches/avoids Croak() in lib function
            or return 0;
        }

    $self->{  AsHash} = {};
    $self->{Sections}{$GLOBAL_SECTION} = {};

    my $CurrentHash    = $self->{  AsHash};
    my $GlobalSection  = $self->{Sections}{$GLOBAL_SECTION};
    my $CurrentSection = $GlobalSection;

    my $LineNo = -1;
    foreach my $Line (@{$self->{Lines}}) {

        chomp $Line;
        $LineNo++;

        foreach my $Match (@{$self->{Matches}}) {

            next
                unless( $Line =~ /$Match->{RegEx}/ );

            #
            # SkipLine - Skip comments and the like
            #
            last
                if $Match->{Action} == SkipLine;
                
            my $Var1 = $1;
            my $Var2 = $2;

            my $Name = $Match->{Name};
            unless( defined $Name and length $Name ) {
                $Name = $Var1;
                $Var1 = $Var2;
                }

            #
            # StartSection - Start a new section with specified name
            #
            if( $Match->{Action} == StartSection ) {
                $self->{Sections}{$Name} = { LineNo => $LineNo };
                $self->{  AsHash}{$Name} = {};
                $CurrentSection = $self->{Sections}{$Name};
                $CurrentHash    = $self->{  AsHash}{$Name};
                next;
                }

            #
            # EndSection - Switch back to "Global"
            #
            elsif( $Match->{Action} == EndSection ) {
                my $CurrentSection = $GlobalSection;
                my $CurrentHash    = $self->{AsHash};
                next;
                }

            #
            # AddGlobal - Add a variable to the global section (even if currently
            #               in a different section)
            #
            elsif( $Match->{Action} == AddGlobal ) {
                $GlobalSection->{$Name} = { Value => $Var1, LineNo => $LineNo };
                $self->{ AsHash}{$Name} = $Var1;
                next;
                }

            elsif( $Match->{Action} == AddVar ) {
                $CurrentSection->{$Name} = { Value => $Var1, LineNo => $LineNo };
                $CurrentHash   ->{$Name} = $Var1;
                next;
                }

            else {
                die "Config::Parse: Unknown parse action ($Match->{Action})";
                }
            }
        }

    return $self->{AsHash};
    }


########################################################################################################################
########################################################################################################################
#
# AddLines - Append lines to the existing config lines
#
# Inputs:   Array of lines to append, either as function args or refs
#
# Outputs:  None.
#
sub AddLines {
    my $self = shift;

    while(1) {
        my $Arg = shift;

        last
            unless defined $Arg;

        if( ref($Arg) eq "ARRAY" ) {
            push @{$self->{Lines}},@$Arg;
            next;
            }

        push @{$self->{Lines}}, $Arg;
        }
    }


########################################################################################################################
########################################################################################################################
#
# Update - Update variables in the parsed config file
#
# Inputs:   Filename to update (default: uses internal filename)
#
# Outputs:  TRUE  if file parsed correctly
#           FALSE if an error occurred (check $! for more info)
#
sub Update {
    my $self     = shift;
    my $Filename = shift // $self->{Filename};

    $self->{Filename} = $Filename;

    #
    #  ->{Sections}                    Hash of sections by name
    #      ->{$SecName}
    #          ->{$Var}                Variables found in section
    #              ->{Value}           Value of variable
    #              ->{LineNo}          Line # where value was found
    #              ->{NewValue}        New value to set during update call
    #
    my $Changed = 0;

    foreach my $SectionName (keys %{$self->{Sections}}) {
        foreach my $VarName (keys %{$self->{Sections}{$SectionName}}) {
            my $Var = $self->{Sections}{$SectionName}{$VarName};

            next
                unless defined $Var;

            next
                unless ref $Var eq "HASH";

            next
                unless defined $Var->{NewValue};

            next
                unless defined $Var->{Value};

            next
                unless $Var->{NewValue} ne $Var->{Value};

            $self->{Lines}[$Var->{LineNo}] =~ s/\Q$Var->{Value}\E/\Q$Var->{NewValue}\E/g;
            $Changed = 1;
            }
        }

    return
        unless $Changed;

    #
    # The write_file() function doesn't have an "unchomp" option?
    #
    @{$self->{Lines}} = map { $_ .= "\n" } @{$self->{Lines}};

    write_file($Filename,$self->{Lines});

#use Data::Dumper;
#print Data::Dumper->Dump([$self->{Lines}],["$self->{Filename}"]);
    }


########################################################################################################################
########################################################################################################################
#
# Comment - Comment out a section or variable
#
# Inputs:   Ref to hash within the "Sections" area of the class
#           Comment action to take (ex: Site::ParseData::CommentHash)
#
# Outputs:  None.
#
sub Comment {
    my $self = shift;
    my $Hash = shift;
    my $CommentStyle = shift // CommentHash;

    #
    # As of this writing, only "CommentHash" is implemented.
    #
    if( $CommentStyle == CommentHash ) {
        $self->{Lines}[$Hash->{LineNo}] = "# " . $self->{Lines}[$Hash->{LineNo}]
            if ref $Hash eq "HASH" and defined $Hash->{LineNo};

        foreach my $Var (values %{$Hash}) {
            $self->{Lines}[$Var->{LineNo}] = "# " . $self->{Lines}[$Var->{LineNo}]
                if ref $Var eq "HASH" and defined $Var->{LineNo}
                   and substr($self->{Lines}[$Var->{LineNo}],0,1) ne "#";
            }
        }
    }



#
# Perl requires that a package file return a TRUE as a final value.
#
1;
