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
##      Site::Process.pm
##
##  DESCRIPTION
##
##      Functions for managing external processes: TimeoutCommand() and BackgroundCommand()
##
##      TimeoutCommand() will execute an external system command, and call ErrorReboot if the command does not
##        complete within the timeout. This is useful for things like an external device which may take a variable
##        amount of time initialize and become ready, but which also may hang and could benefit from a complete
##        reboot. Cell modems and the AP libraries work that way.
##
##      BackgroundCommand() will execute an external system command in the background, and will return the PID
##        of the resulting process. EndBackgroundCommand($PID) will kill the executing command. This is useful
##        for processes that are completely simple and don't need all the process management that perl/fork
##        can supply.
##
##      The process system is specific for RasPi debugging. A call to ErrorReboot() will nominally reboot the
##        system in 60 seconds, but if a user is logged in the reboot will be delayed - on the assumption that
##        the logged-in user is working to improve the system (or wants to debug what went wrong). When all users
##        subsequently log out, the reboot then happens as normal.
##
##      Note on previous: If the variable $USERS_ARE_SSH_USERS is set (see below), then only SSH users will prevent
##        the system from rebooting. If this variable is missing or set to false, then *any* logged-in users will
##        prevent the system from rebooting, including ones using the local display and KB.
##
##      So if your OS is set to automatically log in a local user, which is the default for the GUI version of
##        Raspbian, the system will NEVER reboot if the app fails. If you are selling a product that automatically
##        logs in the GUI user, you want to set $USERS_ARE_SSH_USERS below to allow the system to reboot if your
##        application exits. If you are using the command-line OS, or if the GUI doesn't automatically log in
##        a user, then don't set that variable.
##
##  DATA
##
##      None.
##
##  FUNCTIONS
##
##      TimeoutCommand($Cmd,$Timeout)   # Execute command with timeout
##      BackgroundCommand($CMD)         # Execute command in background
##      EndBackgroundCommand($PID)      # End command running in background
##      EndBackgroundCommands()         # End all commands running in background
##
##      ErrorReboot($Msg)               # Print message and reboot system
##
##  ISA
##
##      None.
##
##  NOTES
##
##      This cut/paste from an existing, working application (not a library) into a library
##        is probably better addressed as an object rather than a list of functions. Only one
##        library instance can be used by any process at one time and I don't know a good way to
##        objectivize $SIG{ALRM} and $SIG{CHLD}, so it's OK for the present.
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

package Site::Process;
    use base "Exporter";

use strict;
use warnings;
use Carp;

use POSIX ":sys_wait_h";

use Sys::Syslog qw(:standard :macros);

use Site::RasPiUtils;

our $VERSION = '2020.08_16';

our @EXPORT  = qw(&TimeoutCommand
                  &BackgroundCommand
                  &EndBackgroundCommand
                  &EndBackgroundCommands
                  &ErrorReboot
                  &Message
                  &ConsoleMessage
                  );               # Export by default

########################################################################################################################
########################################################################################################################
##
## Data declarations
##
########################################################################################################################
########################################################################################################################

our %BackgroundCommands;

$SIG{ALRM} = \&Timeout;
$SIG{CHLD} = \&ChildExit;

our $SysCommand;
our $SysTimeout;

#
# If this next variable is set, only logged-in SSH users will prevent the ErrorReboot() from rebooting.
#
# If the variable is unset or missing, *any* logged in user will prevent the reboot.
#
our $USERS_ARE_SSH_USERS = 1;

#######################################################################################################################
########################################################################################################################
##
## TimeoutCommand - Execute a system command, with timeout. Reboot if system times out
##
## Inputs:      System command to execute (ie: "ifconfig")
##              Timeout for command, in seconds (DEFAULT: 60)
##
## Outputs:     Text response of command, if successful
##
## NOTE: Reboots the system on timeout.
##
sub TimeoutCommand {
    $SysCommand = shift;            # Note: Make global for timeout/error function
    $SysTimeout = shift // 60;

    my $Rtnval;

    eval {
        alarm $SysTimeout;

        $Rtnval = `$SysCommand`;

        alarm 0;
        };

    ErrorReboot("Error executing $SysCommand ($!)")
        if $@;
        
    return $Rtnval;
    }


########################################################################################################################
########################################################################################################################
##
## Timeout - Process timeout of system command
##
## Inputs:      None (called as signal handler)
##
## Outputs:     None - reboots the system
##
sub Timeout { ErrorReboot("Timeout ($SysTimeout secs) executing $SysCommand ($!)"); }


########################################################################################################################
########################################################################################################################
##
## BackgroundCommand - Execute a system command in the background.
##
## Inputs:      System command to execute (ie: "ifconfig")
##
## Outputs:     PID of resulting process
##
sub BackgroundCommand {
    my $Command = shift;
    my $PID;

    exec $Command
        unless $PID = fork();

    #
    # Make note of the PID and child command, in case it exits and we need to print out an error msg
    #
    $BackgroundCommands{$PID} = $Command;

    Message("BackgroundCommand: $BackgroundCommands{$PID} (PID=>$PID)");

    return $PID;
    }


########################################################################################################################
########################################################################################################################
##
## EndBackgroundCommand - Kill a background command
##
## Inputs:      PID of background command already started
##
## Outputs:     None.
##
sub EndBackgroundCommand {
    my $PID = shift;

    Message("Stopping $BackgroundCommands{$PID} (PID $PID)");

    #
    # Remove the $BackgroundCOmmands{$PID} first, so we know tha tthe child exit is expected.
    #
    delete $BackgroundCommands{$PID};

    kill "KILL",$PID;
    }


########################################################################################################################
########################################################################################################################
##
## EndBackgroundCommands - Kill all currently running background commands
##
## Inputs:      None.
##
## Outputs:     None.
##
sub EndBackgroundCommands {

    EndBackgroundCommand($_)
        foreach keys %BackgroundCommands;
    }

    
########################################################################################################################
########################################################################################################################
##
## ChildExit - Manage exit of background child process
##
## Inputs:      None (called as signal handler)
##
## Outputs:     None - reboots the system
##
sub ChildExit { 
    my $PID = waitpid(-1, WNOHANG);

    return
        if $PID == -1;      # == No child waiting

    return
        if $PID ==  0;      # == Children, none terminated

    my $Command = $BackgroundCommands{$PID};

    return
        unless defined $Command;

    #
    # If there's no entry in the BackgroundProcess list for thie PID, then it means the
    #   child was a direct command (and not meant to be in the background).
    #
    # Returning is expected, so ignore those.
    #
    print "SysCommand complete: $SysCommand\n"
        if !defined $Command && substr($SysCommand,0,10) ne "sudo sh -c";   # Unnecessary, and messes up printed output

    return
        unless defined $Command;

    ErrorReboot("Reboot due to command exit: $Command (PID $PID)"); 
    }


########################################################################################################################
########################################################################################################################
##
## ErrorReboot - Log an error, then reboot
##
## Inputs:      Message to log
##
## Outputs:     None - reboots the system
##
sub ErrorReboot {
    my $ErrorMsg = shift;

    Message("",1);
    Message("$ErrorMsg",1);

    if( Users() > 0 ) {
        Message("No reboot, due to user login.",1);
        Message("",1);
        WatchUsers();
        }

    Message("Critical error - rebooting in 60 seconds.",1);
    Message("",1);
    Message("",1);

    sleep(60);

    if( Users() > 0 ) {
        Message("No reboot, due to user login.",1);
        Message("",1);
        WatchUsers();
        }

    Message("Rebooting ",1);

    exec "sudo reboot";
    }


########################################################################################################################
########################################################################################################################
##
## WatchUsers - Watch for user logouts, then reboot the system
##
## Inputs:      None.
##
## Outputs:     None. Will reboot when users log out
##
## NOTE: If the user doesn't fix the problem but logs out, the system would never reboot. Keep watching
##         the user logins, and if they go to zero, reinstate the reboot timeout.
##
sub WatchUsers {

    while(1) {
        sleep 10;

        ErrorReboot("Reinstating reboot timer due to user logout.")
            unless Users();
        }
    }


########################################################################################################################
########################################################################################################################
##
## Users - Return number of users in system
##
## Inputs:      None.
##
## Outputs:     Number of users
##
## NOTE: If $USERS_ARE_SSH_USERS, only the number of SSH users will be returned. Otherwise,
##         the number of all users are returned.
##
sub Users {

    return NumSSHUsers()
        if defined $USERS_ARE_SSH_USERS and $USERS_ARE_SSH_USERS;

    return NumUsers();
    }


########################################################################################################################
########################################################################################################################
##
## Message - Show message to the user
##
## Inputs:      Msg        Message to print
##              Fail       If message indicates a failure, (==1) print in Red, else (==0) print in Green
##
## Outputs:  None.
##
sub Message {
    my $Msg  = shift // "";
    my $Fail = shift // 0;

    #
    # Put the message in 3 places: System log, boot screen, and program log (captured from STDOUT)
    #
    ConsoleMessage ("**** AppDaemon: $Msg",$Fail);
    syslog(LOG_CRIT,"**** AppDaemon: $Msg");

    print "**** AppDaemon: $Msg\n";
    }


########################################################################################################################
########################################################################################################################
##
## ConsoleMessage - Show message in boot screen
##
## Inputs:      Msg        Message to print
##              Fail       If message indicates a failure, (==1) print in Red, else (==0) print in Green
##
## Outputs:  None.
##
sub ConsoleMessage {
    my $Msg  = shift;
    my $Fail = shift // 0;

    return
        unless IAmRoot();

    #
    # Colors for boot console messages
    #
    my $RED   = '\033[0;31m';
    my $GREEN = '\033[0;32m';
    my $NC    = '\033[0m';          # No Color

    if( $Fail ) { TimeoutCommand("sudo sh -c 'echo \"[${RED}FAILED${NC}] $Msg\"   >/dev/tty0'"); }
    else        { TimeoutCommand("sudo sh -c 'echo \"[${GREEN}  OK  ${NC}] $Msg\" >/dev/tty0'"); }
    }



#
# Perl requires that a package file return a TRUE as a final value.
#
1;
