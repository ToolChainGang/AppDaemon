#!/dev/null
#
########################################################################################################################
########################################################################################################################
##
##      Copyright (C) 2020 Peter Walsh, Milford, NH 03055
##      All Rights Reserved under the MIT license as outlined below.
##
##  FILE
##      Site::WSServer.pm
##
##  DESCRIPTION
##
##      Websocket server functions
##
##  DESCRIPTION
##      Simple functions for dealing with persistent server (in particular, the list of connections)
##
##  DATA
##
##      $::Server                           # Singular server object
##
##  FUNCTIONS
##
##      InitWSServer($Port,$WatchedUnits,
##                  \&WebRequest,
##                  \&ConnectRequest)       # Initialize and return state object
##      $Server = GetServer()               # Return current server object
##
##      UpdateClients($State)               # Update all clients with $State struct
##      SendToClients($State,$Conn)         # Send state  to all clients
##      SendResponse($Conn,$Resp)           # Send struct to one client
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

package Site::WSServer;
    use base "Exporter";

use strict;
use warnings;
use Carp;

use Net::WebSocket::Server;
use JSON::PP;

use Site::Process;

our @EXPORT  = qw(&InitWSServer
                  &GetServer
                  &SendToClients
                  &SendResponse);    # Export by default

########################################################################################################################
########################################################################################################################
##
## Data declarations
##
########################################################################################################################
########################################################################################################################

my $Server;

########################################################################################################################
########################################################################################################################
##
## InitWSServer - Initialize and return state object
##
## Inputs:      Port to open server on
##              Ref to array of units to monitor
##              Function to handle web requests
##              Function to handle connection requests
##
## Outputs:     Server object
##
sub InitWSServer {
    my $ServerPort     = shift;
    my $ReadUnits      = shift;
    my $WebRequest     = shift;
    my $ConnectRequest = shift;
    
    $Server = Net::WebSocket::Server->new(
        listen => $ServerPort,

#        watch_readable => [ $ReadUnits ],

        on_connect => sub {
            my $Server = shift;
            my $Conn   = shift;
            Message("Connection " . (scalar ($Server->connections())) . " from " . $Conn->ip() . ":" . $Conn->port());

            $Conn->disconnect(1008, "Denied by server")
                unless &$ConnectRequest($Conn,$Server);

            $Conn->on(

                ##############################################################################
                #
                # UTF8 - Web page sent us a msg in UTF8 format
                #
                utf8 => sub { my $Conn = shift;
                              my $JSON = shift;
                              &$WebRequest($JSON,$Conn,$Server); 
                              },

                ##############################################################################
                #
                # Disconnect - Remote connection is lost
                #
                disconnect => sub {
                    my ($Conn, $Code, $Reason) = @_;
                    Message("Disconnect from " . $Conn->ip());
                    },
                );
            },
        );

    return $Server;
    }


########################################################################################################################
########################################################################################################################
##
## GetServer    - Return the current server object
##
## Inputs:      None.
##
## Outputs:     Current server
##
sub GetServer { return $Server; }


########################################################################################################################
########################################################################################################################
##
## SendToClients - Update all clients with supplied struct
##
## Inputs:      Server (with clients) to update
##
## Outputs:     None.
##
sub SendToClients {
    my $Struct = shift;

    SendResponse($_,$Struct)
        for $Server->connections();
    }


########################################################################################################################
########################################################################################################################
##
## SendResponse - Send struct as response to command
##
## Inputs:      Connection
##              Struct to send
##
## Outputs:     None.
##
sub SendResponse {
    my $Conn     = shift;
    my $Response = shift;

    my $JSONText = eval{JSON::PP->new->pretty->encode($Response)};          # Catches/avoids Croak() in lib function

    return Message("WSServer: Bad JSON encode request: ($Response->{Type})")
        unless defined $JSONText && length $JSONText;

    $Conn->send_utf8($JSONText);
    }


#
# Perl requires that a package file return a TRUE as a final value.
#
1;
