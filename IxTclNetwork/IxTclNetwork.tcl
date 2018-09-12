# Copyright 1997-2018 by IXIA Keysight
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

namespace eval ::IxNet {
    variable _packageVersion "8.50.1501.9"
    variable _packageDirectory [file dirname [info script]]
    variable _transportType {}
    variable _NoApiKey {00000000000000000000000000000000}
    variable OK {::ixNet::OK}
    variable ERROR {::ixNet::ERROR}
    variable _ixNetworkSecureAvailable 0
    variable _ixNetworkSecureDependenciesError {}
    variable _socket {}
    variable _debugFlag 0
    
    source [file join [file dirname [info script]] IxTclNetworkLegacy.tcl]

    if {[catch {
        source [file join [file dirname [info script]] IxTclNetworkSecure.tcl]
        set _ixNetworkSecureAvailable 1
    } requireError]} {
        set _ixNetworkSecureDependenciesError $requireError
        puts "WARNING: Cannot load required dependencies: $requireError\
            \nThis version of IxTclNetwork requires the following tcl packages: tls http json logger websocket.\
            \n\nIf you are trying to connect to a Windows IxNetwork API Server on TCL port you can safely ignore this warning."
        set _ixNetworkSecureAvailable 0
    }

    proc _executeOnCurrentTransport {args} {
        variable _ixNetworkSecureAvailable
        if {$_ixNetworkSecureAvailable && [::IxNetSecure::IsConnected]} {
            return [eval "::ixNetSecure $args"]
        } else {
            return [eval "::ixNetLegacy $args"]
        }
    }

    proc _executeOnSecureTransport {args} {
        variable _ixNetworkSecureAvailable
        variable _ixNetworkSecureDependenciesError
        if {$_ixNetworkSecureAvailable} {
            return [eval "::ixNetSecure $args"]
        } else {
            error "This command requires the following tcl packages: tls http json logger websocket.\n\
                    Cannot load required dependencies: $_ixNetworkSecureDependenciesError"
        }
    }

    proc _detectTransport {hostname port} {
        ::IxNet::Log "debug" "Detecting transport type..."
        set _transport {}
        if {$port == "auto"} {
            set port 8009
            set usingDefaultPorts 1
        } else {
            set usingDefaultPorts 0
        }
        if  {[catch {
            set ::IxNet::_socket [socket $hostname $port]
            ::IxNet::Log "Connected to $hostname:$port"
            fconfigure $::IxNet::_socket -blocking 0
            fileevent $::IxNet::_socket readable {
                set ::IxNet::_connectWaitHandle valid
            }
    
            set id [after 15000 {
                ::IxNet::Log "debug" "Timeout occured while waiting for socket to become readable"
                set ::IxNet::_connectWaitHandle invalid
            }]

            # wait for a response from the endpoint
            vwait ::IxNet::_connectWaitHandle
            # disable the timeout mechanism
            fileevent $::IxNet::_socket readable {}
          
            catch {after cancel $id}
            # process the results from the endpoint
            switch $::IxNet::_connectWaitHandle {
                "valid" {
                    set response [read $::IxNet::_socket 256]
                    ::IxNet::Log "debug" "Server responese: $response"
                    if { [string first "<001" $response] == 0 || \
                         [string first "Server: IxNetwork API Server" $response] >= 0 || \
                         [string first "Server: Connection Manager" $response] >= 0 } {	
                        set _transport "::ixNetLegacy"
                    } else {
                        set _transport "::ixNetSecure"    
                    }
                    close $::IxNet::_socket
                    set ::IxNet::_socket {}

                }
                "invalid" {
                    close $::IxNet::_socket
                    set ::IxNet::_socket {}
                    set _transport "::ixNetSecure"
                }
		    }
        } err]} {
            if {$::IxNet::_socket != ""} {
                close $::IxNet::_socket
                set ::IxNet::_socket {}
            }
            if {!$usingDefaultPorts} {
                error "Unable to connect to ${hostname}:${port}. Error: $err."
            }
        }
        if {$::IxNet::_socket != ""} {
            close $::IxNet::_socket
            set ::IxNet::_socket {}
        }

        if {$usingDefaultPorts && $_transport == ""} {
            set _transport "::ixNetSecure"
        }
        if {$_transport == ""} {
            if {$usingDefaultPorts} {
                set host "$hostname using default ports (8009, 443)"
            } else {
                set host "$hostname:$port"
            }
            error "Unable to connect to ${host}. Error: Host is unreachable."
        }
        ::IxNet::Log "Using transport $_transport"
        return $_transport
    }

    proc SetDebug {debugFlag} {
        variable _debugFlag
        variable _ixNetworkSecureAvailable
        ::IxNetLegacy::SetDebug $debugFlag
        if {$_ixNetworkSecureAvailable} {
            ::IxNetSecure::SetDebug $debugFlag
        }
    }

    proc Log {level args} {
        variable _debugFlag
        if {$_debugFlag} {
            puts "\[[clock format [clock seconds]\] \[IxNet\] \[$level\]  $args"
        }
    }

    proc IsConnected {} {
        variable _ixNetworkSecureAvailable
        if {$_ixNetworkSecureAvailable} {
            return [expr [::IxNetLegacy::IsConnected] || [::IxNetSecure::IsConnected]]
        }
        return [::IxNetLegacy::IsConnected];
    }
    proc GetVersion {} {
        variable _packageVersion
        if {[IsConnected]} {
            return [_executeOnCurrentTransport "getVersion"]
        } else {
            return $_packageVersion
        }
    }
    proc Disconnect {} {
        variable _transportType
        set ret [_executeOnCurrentTransport "disconnect"]
        set _transportType {}
        return $ret
    }
}


proc ::ixNet {args} {
    set secureCommands {getApiKey getRestUrl getSessions clearSession clearSessions}
    set legacyCommandPatterns {getSessionInfo getRoot getNull help connect disconnect setSessionParameter getVersion add commit readFrom writeTo exec* setA* setM* connectiontoken setDebug}
    set commandPatterns "$secureCommands $legacyCommandPatterns"

	if {[llength $args] == 0} {
		error "Unknown command"
	}
    set isSecureCommand 0
	set command {}
	foreach {arg} $args {
		if {[string first - $arg] == 0} {
			continue
		}
		set patternIndex [lsearch -glob $commandPatterns $arg]
        set isSecureCommand [expr [lsearch -glob $secureCommands $arg] != -1]
		if {$patternIndex != -1} {
			set command [lindex $commandPatterns $patternIndex]
		}
		break
	}
    switch -glob $command {
        "setDebug" {
            if {[llength $args] < 2} {
                error "missing required arguments"
            }
            return [::IxNet::SetDebug [lrange $args 1 end]]
        }
        "getVersion" {
            return [IxNet::GetVersion]
        }
        "getApiKey" {
            if {[llength $args] < 2} {
                error "SyntaxError: This method requires at least the hostname argument. \
                        An example of a correct method call is: \n\t\
                        ixNet getApiKey <hostname> -username <username> -password <password> \[-port <443>\] \[-apiKeyFile <api.key>\]"
            }
            set hostname [lindex $args 1]
            if {$::IxNet::_ixNetworkSecureAvailable} {
                return [eval "::IxNet::_executeOnSecureTransport $args"]
            } else {
                puts "Warning: Unable to get API key from $hostname due to missing dependencies\
                        (see documentation for required dependencies).\
                        If you are trying to connect to a Windows IxNetwork API Server on TCL port you can safely ignore this warning."
                return $::IxNet::_NoApiKey
            }
        }
        "connect" {
            if {[::IxNet::IsConnected] || $::IxNet::_ixNetworkSecureAvailable == 0} {
                return [eval "::IxNet::_executeOnCurrentTransport $args"]
            } else {
                if {[llength $args] < 2} {
                    return [IxNet::Usage $command "missing required arguments"]
                }
                set hostname [lindex $args 1]
			    if {![regexp -nocase -- {-port (\d+)} $args {} port]} {
                    set port {auto}    
                }
                return [eval "[::IxNet::_detectTransport $hostname $port] $args"]
            }
        }
        "disconnect" {
           return [::IxNet::Disconnect]
        }
        default {
            if {$isSecureCommand} {
                return [eval "::IxNet::_executeOnSecureTransport $args"]
            } else {
                return [eval "::IxNet::_executeOnCurrentTransport $args"]
            }
        }
    }


}
