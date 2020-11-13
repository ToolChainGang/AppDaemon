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
##      ->{Parsed}                      TRUE if data (file or lines) successfully parsed
##      ->{Changed}                     TRUE if something changed after parsed
##      ->{Sections}                    Hash of sections by name
##          ->{$SecName}
##              ->{LineNo}              Line number of section starter
##              ->{Vars}                Variables found in section
##                  ->{$Var}            Variables found in section
##                      ->{Value}       Value of variable
##                      ->{LineNo}      Line # where value was found
##                      ->{NewValue}    New value to set during update call
##
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
##      ->Init()                        Clear out data, for future parsing
##
##      ->ParseFile($Filename)          Parse specified file
##      ->ParseLines(@Lines)            Parse list of lines
##      ->ParseCommand($Cmd)            Parse output of external command
##      ->Parse()                       Parse $self->{Lines}
##
##      ->AsHash() => {}                Return hash version of parsed data
##          ->{$Var} => $Value          Variable in GLOBAL section
##          ->{$Section}                Named section
##              ->{$Var}=>$Value        Value of variable in section
##
##      ->AddLines($Line,@Lines...)     Add more lines to file
##
##      ->CommentLine($LineNo,$Type)        Comment out a line, using supplied function
##      ->CommentVar($Section,$Var,$Type)   Comment out a specific variable
##      ->CommentSection($Section,$Type)    Comment out entire section, including section header
##
##      ->Update()                      Update specified file with new data
##
##      ->SaveFile($Filename)           Save modified file
##
##  NOTE: The special section "Global" contains variables not otherwise in a section.
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
use constant CommentSemi    => 2;       # Commented by prepending semicolon
use constant CommentCPP     => 3;       # Commented by prepending //
use constant CommentC       => 4;       # Commented by /* .. */, as in original C
use constant CommentHTML    => 5;       # Commented by <!-- .. -->, as in HTML

our $GLOBAL_SECTION = "Global";

########################################################################################################################
########################################################################################################################
#
# Site::ConfigFile - Parse a config file
#
# Inputs:   List of action to take while parsing
#           [Optional] Filename to parse
#
# Outputs:  Parsed config info
#
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $Args  = { @_ };
    my $self  = bless $Args,$class;

    $self->Init();
    $self->{Lines} = [];

    return $self;
    }


########################################################################################################################
########################################################################################################################
#
# Init - Clear out data, in preparation for parsing
#
# Inputs:   None.
#
# Outputs:  None.
#
sub Init {
    my $self     = shift;
    my $Filename = shift // $self->{Filename};

    $self->{  Parsed} = 0;
    $self->{ Changed} = 0;
    $self->{Sections} = {};
    $self->{Sections}{$GLOBAL_SECTION} = {};
    }


########################################################################################################################
########################################################################################################################
#
# ParseFile - Parse a config file
#
# Inputs:   Filename to parse (default: uses internal filename)
#
# Outputs:  TRUE  if file parsed correctly
#           FALSE if an error occurred (check $! for more info)
#
sub ParseFile {
    my $self     = shift;
    my $Filename = shift // $self->{Filename};

    $self->Init();

    $self->{Filename} = $Filename;
    $self->{   Lines} = [];
    @{$self->{Lines}} = eval{read_file($Filename)}      # Catches/avoids Croak() in lib function
        or return 0;

    return $self->Parse();
    }


########################################################################################################################
########################################################################################################################
#
# ParseLines - Parse user-supplied lines
#
# Inputs:   List of lines (or arrays of lines) to parse
#
# Outputs:  TRUE  if lines parsed correctly
#           FALSE if an error occurred (check $! for more info)
#
sub ParseLines {
    my $self = shift;

    $self->Init();
    $self->{Lines} = [];
    $self->AddLines(@_);
    $self->{Changed} = 0;

    return $self->Parse();
    }


########################################################################################################################
########################################################################################################################
#
# ParseCommand - Parse command output from external command
#
# Inputs:   Command to execute and parse
#
# Outputs:  TRUE  if lines parsed correctly
#           FALSE if an error occurred (check $! for more info)
#
sub ParseCommand {
    my $self    = shift;
    my $Command = shift;

    $self->Init();
    $self->{Lines} = [];

    @{$self->{Lines}} = eval{`$Command`}      # Catches/avoids Croak() in lib function
        or return 0;

    return $self->Parse();
    }


########################################################################################################################
########################################################################################################################
#
# Parse - Parse the existing set of lines
#
# Inputs:   None.
#
# Outputs:  TRUE  if file parsed correctly
#           FALSE if an error occurred (check $! for more info)
#
# NOTE: Intended for internal use, but not a problem if an external call happens.
#
sub Parse {
    my $self = shift;

    $self->Init();

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
                $self->{Sections}{$Name} = { LineNo => $LineNo, Vars => {} };
                $CurrentSection = $self->{Sections}{$Name};
                next;
                }

            #
            # EndSection - Switch back to "Global"
            #
            elsif( $Match->{Action} == EndSection ) {
                my $CurrentSection = $GlobalSection;
                next;
                }

            #
            # AddGlobal - Add a variable to the global section (even if currently
            #               in a different section)
            #
            elsif( $Match->{Action} == AddGlobal ) {
                $GlobalSection->{Vars}{$Name} = { Value => $Var1, LineNo => $LineNo };
                next;
                }

            elsif( $Match->{Action} == AddVar ) {
                $CurrentSection->{Vars}{$Name} = { Value => $Var1, LineNo => $LineNo };
                next;
                }

            else {
                die "Config::Parse: Unknown parse action ($Match->{Action})";
                }
            }
        }

    $self->{Parsed} = 1;

    return $self->AsHash();
    }


########################################################################################################################
########################################################################################################################
#
# AsHash - Return pure perl hash of data
#
# Inputs:   None.
#
# Outputs:  Pure perl hash of parsed data
#
sub AsHash {
    my $self = shift;

    my $Hash = {};
    my $CurrentSection;

    foreach my $Section (keys %{$self->{Sections}}) {
        if( $Section eq $GLOBAL_SECTION ) { $CurrentSection = $Hash }
        else {
            $Hash->{$Section} = {};
            $CurrentSection = $Hash->{$Section};
            }

        foreach my $Var (keys %{$self->{Sections}{$Section}{Vars}}) {
            $CurrentSection->{$Var} = $self->{Sections}{$Section}{Vars}{$Var}{Value};
            }        
        }

    return $Hash;
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

    #
    # Go through all arguments, adding lines and arrays as found
    #
    while(1) {
        my $Arg = shift;

        last
            unless defined $Arg;

        if( ref($Arg) eq "ARRAY" ) {
            push @{$self->{Lines}},@{$Arg};
            $self->{Changed} = 1;
            next;
            }

        die "$self: Not a line or array of lines."
            if ref($Arg);

        push @{$self->{Lines}},$Arg;
        $self->{Changed} = 1;
        }
    }


########################################################################################################################
########################################################################################################################
#
# FromHash - Set new values, based on passed hashref
#
# Inputs:   Hashref to check
#
# Outputs:  None.
#
sub FromHash {
    my $self = shift;
    my $Hash = shift;

    my $CurrentSection;

    foreach my $Section (keys %{$self->{Sections}}) {
        if( $Section eq $GLOBAL_SECTION ) { $CurrentSection = $Hash }
        else {
            next
                unless defined $Hash->{$Section};

            $CurrentSection = $Hash->{$Section};
            }

        foreach my $Var (keys %{$self->{Sections}{$Section}{Vars}}) {
            next
                unless defined $CurrentSection->{$Var};

            next
                if $CurrentSection->{$Var} eq $self->{Sections}{$Section}{Vars}{$Var}{Value};

            $self->{Sections}{$Section}{Vars}{$Var}{NewValue} = $CurrentSection->{$Var};
            $self->{Changed} = 1;
            }        
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
    my $self = shift;

    #
    #  ->{Sections}                    Hash of sections by name
    #      ->{$SecName}
    #          ->{LineNo}              Line # of section identifier
    #          ->{Vars}                Variables found in section
    #              ->{$Var}                Name of variable
    #                  ->{Value}           Value of variable
    #                  ->{LineNo}          Line # where value was found
    #                  ->{NewValue}        New value to set during update call
    #
    foreach my $SectionName (keys %{$self->{Sections}}) {

        foreach my $VarName (keys %{$self->{Sections}{$SectionName}{Vars}}) {
            my $Var = $self->{Sections}{$SectionName}{Vars}{$VarName};

            next
                unless ref $Var eq "HASH";

            next
                unless defined $Var->{LineNo};

            next
                unless defined $Var->{Value};

            next
                unless defined $Var->{NewValue};

            next
                unless $Var->{NewValue} ne $Var->{Value};

            $self->{Lines}[$Var->{LineNo}] =~ s/\Q$Var->{Value}\E/\Q$Var->{NewValue}\E/g;

            $self->{Changed} = 1;
            }
        }
    }


########################################################################################################################
########################################################################################################################
#
# SaveFile - Parse a config file
#
# Inputs:   Filename to save to (default: uses internal filename)
#
# Outputs:  TRUE  if file saved correctly
#           FALSE if an error occurred (check $! for more info)
#
sub SaveFile {
    my $self     = shift;
    my $Filename = shift // $self->{Filename};

    $self->{Filename} = $Filename;

    #
    # The write_file() function doesn't have an "unchomp" option?
    #
    my @OutLines = map { $_ .= "\n" } @{$self->{Lines}};

    write_file($Filename,@OutLines);

#use Data::Dumper;
#print Data::Dumper->Dump([$self->{Lines}],["$self->{Filename}"]);

    }


########################################################################################################################
########################################################################################################################
#
# CommentLine - Comment out a line, using supplied function
#
# Inputs:   Lineno to comment
#           Comment action to take (DEFAULT: Site::ParseData::CommentHash)
#
# Outputs:  None.
#
sub CommentLine {
    my $self   = shift;
    my $LineNo = shift;

    my $CommentStyle = shift // CommentHash;

    return
        unless defined $LineNo;

    if( $CommentStyle == CommentHash ) {
        $self->{Lines}[$LineNo] = "# " . $self->{Lines}[$LineNo]
            unless $self->{Lines}[$LineNo] =~ /^# /;
        return;
        }

    if( $CommentStyle == CommentCPP ) {
        $self->{Lines}[$LineNo] = "// " . $self->{Lines}[$LineNo]
            unless $self->{Lines}[$LineNo] =~ #^// #;
        return;
        }

    if( $CommentStyle == CommentC ) {
        $self->{Lines}[$LineNo] = "/* " . $self->{Lines}[$LineNo] . " */"
            unless $self->{Lines}[$LineNo] =~ #^/* .* */#;
        return;
        }

    if( $CommentStyle == CommentHTML ) {
        $self->{Lines}[$LineNo] = "<!-- " . $self->{Lines}[$LineNo] . " -->"
            unless $self->{Lines}[$LineNo] =~ #^<\!-- .* -->#;
        return;
        }
    }


########################################################################################################################
########################################################################################################################
#
# CommentVar - Comment out a specific var, within section
#
# Inputs:   Section containing var
#           Variable to comment out
#           Comment action to take (DEFAULT: Site::ParseData::CommentHash)
#           
# Outputs:  None.
#
sub CommentVar {
    my $self    = shift;
    my $Section = shift;
    my $Var     = shift;

    my $CommentStyle = shift // CommentHash;

    return
        unless defined $Section;

    return
        unless defined $self->{Sections}{$Section};

    return
        unless defined $Var;

    return
        unless defined $self->{Sections}{$Section}{Vars}{$Var};

    $self->CommentLine($self->{Sections}{$Section}{Vars}{$Var}{LineNo});
    }


########################################################################################################################
########################################################################################################################
#
# CommentSection - Comment out an entire section, including section header
#
# Inputs:   Section to be commented
#           Comment action to take (DEFAULT: Site::ParseData::CommentHash)
#           
# Outputs:  None.
#
sub CommentSection {
    my $self    = shift;
    my $Section = shift;

    my $CommentStyle = shift // CommentHash;

    return
        unless defined $Section;

    return
        unless defined $self->{Sections}{$Section};

    $self->CommentLine($self->{Sections}{$Section}{LineNo});

    $self->CommentLine($_->{LineNo})
        foreach values %{$self->{Sections}{$Section}{Vars}};
    }



#
# Perl requires that a package file return a TRUE as a final value.
#
1;
