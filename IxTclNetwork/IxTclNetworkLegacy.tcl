# Copyright 1997-2019 by IXIA Keysight
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

namespace eval ::IxNetLegacy {
	variable commandPatterns {getSessionInfo getRoot getNull help connect disconnect setSessionParameter getVersion add commit readFrom writeTo exec* setA* setM* connectiontoken setDebug}
	variable _isClientTcl true
	variable _debugFlag false
	variable _ipAddress {}
	variable _port {}
	variable _sessionId {}
	variable _serverusername {}
	variable _tclResult {}
	variable _evalResult {}
	variable _socketId {}
	variable _proxySocketId {}
	variable _connectWaitHandle {}
	variable _connectTokens {}
	variable _OK {::ixNet::OK}
	variable _buffer {}
	variable _packageVersion "9.00.1915.16"
	variable _transportType "TclSocket"
	variable STARTINDEX "<"
	variable STOPINDEX ">"
	variable STX "001"
	variable IXNET "002"
	variable RESPONSE "003"
	variable EVALRESULT "004"
	variable READFROM "005"
	variable WRITETO "006"
	variable FILENAME "007"
	variable FILECONTENT "008"
	variable CONTENT "009"
	variable TCL_OK 0
	variable TCL_ERROR 1
	variable BIN2 [binary format "c" 2]
	variable BIN3 [binary format "c" 3]

	proc SetDebug {value} {
		variable _debugFlag
		set _debugFlag $value
	}


    proc Log {level args} {
        variable _debugFlag
		
        if {$_debugFlag} {
        	if { [string length $args] > 1024} {
	            puts "\[[clock format [clock seconds]]\] \[IxNet\] \[$level\]  [string range $args 0 1024]..."
	        } else {
	            puts "\[[clock format [clock seconds]]\] \[IxNet\] \[$level\]  $args"
	        }
        }
		update
    }

	proc SetDefaultSocketModes {} {
		variable _socketId

		if {$_socketId != ""} {
			fconfigure $_socketId -buffersize 131072 -buffering none -translation binary -blocking true -encoding binary
		}
	}
    proc CheckClientVersion {} {
        if { ${::IxNetLegacy::_packageVersion} != [ixNetLegacy getVersion]} {
            puts "WARNING: IxNetwork Tcl library version ${::IxNetLegacy::_packageVersion} is not matching the IxNetwork client version [ixNetLegacy getVersion]"
        }
    }
    
	proc InitialConnect {ipAddress port {options {}}} {
		
		variable _ipAddress
		variable _proxySocketId
		variable _socketId
		variable _connectTokens
		
		# make an initial socket connection
		# this will keep trying as it could be connecting to the proxy
		# which may not have an available application instance at that time
		set _ipAddress $ipAddress
		set attempts 0
		while {1} {
			if {[catch {set _socketId [socket $_ipAddress $port]} errMsg]} {
				if {$_proxySocketId != ""} {
					incr attempts
					after 2000
				} else {
					Close
					error $errMsg
				}
			} else {
				break
			}
			if {$attempts > 120} {
				Close
				error $errMsg
			}
		}
			
		# a socket connection has been made now read the type of connection
		# setup to timeout if the remote endpoint is not valid
		fconfigure $_socketId -blocking 0
		fileevent $_socketId readable {
			set ::IxNetLegacy::_connectWaitHandle valid
		}
		set id [after 90000 {
			set ::IxNetLegacy::_connectWaitHandle invalid
		}]

		# wait for a response from the endpoint
		vwait ::IxNetLegacy::_connectWaitHandle
	
		# disable the timeout mechanism
		fileevent $_socketId readable {}
		::IxNetLegacy::SetDefaultSocketModes
		catch {after cancel $id}

		# process the results from the endpoint
		if {[catch {
			switch $::IxNetLegacy::_connectWaitHandle {
				"valid" {
					set connectString [GetTclResult]
					if {$connectString == "proxy"} {	
						puts -nonewline $_socketId $options
						flush $_socketId
						set _connectTokens [GetTclResult]
						puts "connectiontoken is $_connectTokens"; update
						array set connectTokenArray $_connectTokens
						set _proxySocketId $_socketId
						InitialConnect $_ipAddress $connectTokenArray(-port)
					}
				}
				"invalid" {
					::IxNetLegacy::Close
					error "Connection handshake timed out after 30 seconds; check that the IxNetwork TCL Server is listening at $ipAddress:$port"
				}
			}
		} error]} {
			::IxNetLegacy::Close
			error "Unable to connect to $ipAddress:$port. Error: $error"
		}
	}
	proc Connect {ipAddress port sessionId serverusername options ixNetCommand} {
		variable _ipAddress
		variable _socketId
        variable _port
		variable _serverusername
		variable _sessionId
		variable _OK

		if {$_socketId != ""} {
			if {[catch {Send "ixNet${::IxNetLegacy::BIN2}help"} err]} {
				Close
			}
		}

		if {$_socketId == ""} {
			InitialConnect $ipAddress $port $options
			set _sessionId [::IxNetLegacy::GetSessionId]
			set _serverusername $serverusername
			return [SendBuffer $ixNetCommand]
			
		} else {
			if {$ipAddress != $_ipAddress || $port != $_port } {
				return "Cannot connect to $ipAddress:$port as a connection is already established to $_ipAddress:$_port. Please execute disconnect before trying this command again."
			}
			if { $sessionId != "" &&  $sessionId != $_sessionId } {
				return "Cannot connect to session $sessionId as a connection is already established to session $_sessionId. Please execute disconnect before trying this command again."
			}
			if { $serverusername != "" &&  $serverusername != $_serverusername } {
				return "Cannot connect to a session associated with $serverusername as a connection is already established to a session associated with $_serverusername. Please execute disconnect before trying this command again."
			}
			return $::IxNetLegacy::_OK
		}
	}
	proc Close {} {
		if {$::IxNetLegacy::_proxySocketId != ""} {
			catch {
                puts -nonewline $::IxNetLegacy::_proxySocketId "close"
                flush $::IxNetLegacy::_proxySocketId
                read $::IxNetLegacy::_proxySocketId 1024
            }
		}
		catch {close $::IxNetLegacy::_proxySocketId}
		catch {close $::IxNetLegacy::_socketId}
		set ::IxNetLegacy::_ipAddress {}
		set ::IxNetLegacy::_port {}
		set ::IxNetLegacy::_serverusername {}
		set ::IxNetLegacy::_sessionId {}
		set ::IxNetLegacy::_socketId {}
		set ::IxNetLegacy::_proxySocketId {}
		set ::IxNetLegacy::_evalResult 1
		set ::IxNetLegacy::_tclResult "connection closed"
		set ::IxNetLegacy::_receiveReady true
		set ::IxNetLegacy::_connectTokens {}
		set ::IxNetLegacy::_buffer {}
	}
	proc Disconnect {command} {
		variable _socketId

		set response [::IxNetLegacy::Send $command]

		::IxNetLegacy::Close

		return $response
	}
	proc ThrowError {} {
		set errorMessage $::errorInfo

		::IxNetLegacy::Close

		error $errorMessage
	}
	proc CheckConnection {} {
		variable _socketId

		if {$_socketId != ""} {
			set socketError [fconfigure $_socketId -error]

			if {$socketError != ""} {
				Close
				error "not connected ($socketError)"
			}
		} else {
			error "not connected"
		}
	}
	proc Send {command} {
		variable _socketId
		variable STX
		variable IXNET
		variable CONTENT

		CheckConnection

		if {$_socketId != ""} {
			
			Log "debug" "::IxNetLegacy::Send=<$STX><$IXNET><$CONTENT[string length $command]>$command";
			
			if {[catch {puts -nonewline $_socketId "<$STX><$IXNET><$CONTENT[string length $command]>$command"} errorMessage]} {
				Close
				if {[string first "connection reset by peer" $errorMessage] != -1} {
					error "connection reset by peer"
				} else {
					error $errorMessage
				}
			}

			flush $_socketId

			return [::IxNetLegacy::GetTclResult]

		} else {
			error "not connected"
		}
	}
	proc Read {} {
		variable _tclResult
		variable _evalResult
		variable _socketId
		variable STARTINDEX
		variable STOPINDEX
		variable STX
		variable EVALRESULT
		variable RESPONSE
		variable TCL_OK
		variable TCL_ERROR
		set filename ""

		# read to the stop index
		# read the content length
		while {1} {
			set startIndex -1
			set stopIndex -1
			set commandId ""
			set contentLength 0
			set receiveBuffer ""

			while {$commandId == ""} {
				::IxNetLegacy::CheckConnection
					
				if {[eof $::IxNetLegacy::_socketId]} {
					::IxNetLegacy::Close
					return
				}
					
				if {[catch {append receiveBuffer [read $::IxNetLegacy::_socketId 1]} errorMessage]} {
					::IxNetLegacy::Close
					if {[string first "connection reset by peer" $errorMessage] != -1} {
						error "connection reset by peer"
					} else {
						error $errorMessage
					}
				}

				set startIndex [string first $STARTINDEX $receiveBuffer]
				set stopIndex [string first $STOPINDEX $receiveBuffer]
				if {$startIndex != -1 && $stopIndex != -1} {
					set commandId [string range $receiveBuffer [expr $startIndex + 1] [expr $startIndex + 3]]

					if {[expr $startIndex + 4] < $stopIndex} {
						set contentLength [string range $receiveBuffer [expr $startIndex + 4] [expr $stopIndex - 1]]
					}
					break
				}
			}

			Log "debug" "::IxNetLegacy::Read=$commandId $contentLength";
			
					
			switch -- $commandId {
				"001" {
					set ::IxNetLegacy::_evalResult $TCL_ERROR
					set ::IxNetLegacy::_tclResult {}
					read $_socketId $contentLength
				}
				"003" {
					read $_socketId $contentLength
				}
				"004" {
					set _evalResult [read $_socketId $contentLength]
				}
				"007" {
					set filename [read $_socketId $contentLength]
				}
				"008" {
					if {[catch {file mkdir [file dirname $filename]} errorMessage]} {
						error "unable to create directory [file dirname $filename]"
					}
					if {[catch {set fid [open $filename w]} errorMessage]} {
						error "unable to create file $filename $errorMessage"
					}
					fconfigure $fid -translation binary
					set totalBytesRead 0
					set bytesToRead 32767
					while {$totalBytesRead < $contentLength} {
						if {[expr $contentLength - $totalBytesRead] < $bytesToRead} {
							set bytesToRead [expr $contentLength - $totalBytesRead]
						}
						puts -nonewline $fid [read $_socketId $bytesToRead]
						incr totalBytesRead $bytesToRead
					}
					close $fid
				}
				"009" {
					set ::IxNetLegacy::_tclResult [read $_socketId $contentLength]
					return
				}
				default {
					error "unrecognized command $commandId"
				}
			}
		}
	}
	proc GetTclResult {} {
		variable _socketId
		variable _evalResult
		variable _tclResult

		::IxNetLegacy::Read

		Log "debug" "::IxNetLegacy::GetTclResult= _evalResult=$_evalResult _tclResult=$_tclResult"; 

		

		if {$_evalResult == 1} {
			error $_tclResult
		}

		if {!$::IxNetLegacy::_isClientTcl} {
			set ::IxNetLegacy::_parseResult $_tclResult
			::IxNetLegacy::ParseResult $_tclResult
			if {[string first "list" $::IxNetLegacy::_parseResult] == 0} {
				return [eval $::IxNetLegacy::_parseResult]
			} else {
				return $::IxNetLegacy::_parseResult
			}
		} else {
			return $_tclResult
		}
	}
	proc ParseResult {ixNetResult} {
		set firstList true
		set openReplacement "\[list"

		if {[string first "::ixNet::" $ixNetResult] == 0} {
			return
		}
		
		set ixNetResult [string map [list "\{\}" "${::IxNetLegacy::BIN2}${::IxNetLegacy::BIN3}"] $ixNetResult]
		while {1} {
			set openBrace [string first "\{" $ixNetResult]
			if {$openBrace == -1} {
				break
			}

			# remove next additional side by side open brace and it's corresponding close brace
			while {[string index $ixNetResult [expr $openBrace + 1]] == "\{"} {
				set closeBrace [FindNextClosingBrace $ixNetResult $openBrace]
				if {$closeBrace != -1} {
					set ixNetResult [string replace $ixNetResult [expr $openBrace + 1] [expr $openBrace + 1]]
					incr closeBrace -1
					set ixNetResult [string replace $ixNetResult $closeBrace $closeBrace]
				} else {
					break
				}
			}

			set comma [string first "," $ixNetResult $openBrace]
			set datatype [string range $ixNetResult [expr $openBrace + 1] [expr $comma - 1]]
			set closeBrace [FindNextClosingBrace $ixNetResult $openBrace]
			
			set openReplacement ""
			set closeReplacement ""
			switch $datatype {
				"kArray" -
				"kStruct" {
					if {$firstList} {
						set openReplacement "list "
						set firstList false
					} else {
						set openReplacement "\[list "
						set closeReplacement "\]"
					}
				}
				default {
					if {!$firstList && [string first " " [string range $ixNetResult $openBrace $closeBrace]] != -1} {
						set openReplacement ${::IxNetLegacy::BIN2}
						set closeReplacement ${::IxNetLegacy::BIN3}
					}
				}
			}
			set ixNetResult [string replace $ixNetResult $openBrace $comma $openReplacement]
			set closeBrace [expr $closeBrace - (($comma - $openBrace) - [string length $openReplacement]) - 1]
			set ixNetResult [string replace $ixNetResult $closeBrace $closeBrace $closeReplacement]
		}
		set ::IxNetLegacy::_parseResult [string map [list ${::IxNetLegacy::BIN2} "\{" ${::IxNetLegacy::BIN3} "\}"] $ixNetResult]
		if {$::IxNetLegacy::_parseResult == "{}" } {set ::IxNetLegacy::_parseResult ""}
	}
	proc FindNextClosingBrace {value {startPos 0}} {
		set depth 0

		for {set i $startPos} {$i < [string length $value]} {incr i} {
			if {[string index $value $i] == "\{"} {
				incr depth
			} elseif {[string index $value $i] == "\}"} {
				incr depth -1
				if {$depth == 0} {
					return $i
				}
			}
		}

		return -1
	}
	proc Buffer {command} {
		append ::IxNetLegacy::_buffer $command
		append ::IxNetLegacy::_buffer $::IxNetLegacy::BIN3

		return $::IxNetLegacy::_OK
	}
	proc SendBuffer {command} {
		append ::IxNetLegacy::_buffer $command
		append ::IxNetLegacy::_buffer $::IxNetLegacy::BIN3

		# send the buffer and then clear it
		if {[catch {set result [::IxNetLegacy::Send $::IxNetLegacy::_buffer]} errorMessage]} {
			unset ::IxNetLegacy::_buffer
			error $errorMessage
		}
		unset ::IxNetLegacy::_buffer

		return $result
	}
	proc PutFileOnServer {filename} {
		variable _socketId
		variable BIN2
		variable STX
		variable READFROM
		variable FILENAME
		variable CONTENTLENGTH
		variable CONTENT

		set fid [open $filename RDONLY]
		fconfigure $fid -buffering full -encoding binary -translation binary
		set truncatedFilename [file tail $filename]
		puts -nonewline $_socketId "<$STX><$READFROM><$FILENAME[string length $truncatedFilename]>$truncatedFilename<$CONTENT[file size $filename]>"
		fcopy $fid $_socketId
		flush $_socketId
		close $fid

		SetDefaultSocketModes

		set remoteFilename [::IxNetLegacy::GetTclResult]

		return [::IxNetLegacy::Send "ixNet${BIN2}readFrom${BIN2}${remoteFilename}${BIN2}-ixNetRelative"]
	}
	proc CreateFileOnServer {filename} {
		variable _socketId
		variable BIN2
		variable STX
		variable WRITETO
		variable FILENAME
		variable CONTENT

		puts -nonewline $_socketId "<$STX><$WRITETO><$FILENAME[string length $filename]>$filename<${CONTENT}0>"
		flush $_socketId

		set remoteFilename [::IxNetLegacy::GetTclResult]

		return [::IxNetLegacy::Send "ixNet${BIN2}writeTo${BIN2}${remoteFilename}${BIN2}-ixNetRelative${BIN2}-overwrite"]
	}
	proc IsConnected {} {
		variable _socketId

		if {$_socketId == ""} {
			return false
		} else {
			return true
		}
	}
	proc GetSessionId {} {
		variable BIN2
		set sessionId -1
		if {[::IxNetLegacy::IsConnected]} {
			if {[regexp {sessionId (\d+)} [::IxNetLegacy::SendBuffer "ixNet${BIN2}setSessionParameter"] result sessionId]} {
				return $sessionId
			}
			return -1
		} else {
			error "not connected"
		}
	}

	proc GetVersion {} {
		variable BIN2
		if {[::IxNetLegacy::IsConnected]} {
			return [::IxNetLegacy::SendBuffer "ixNet${BIN2}getVersion"]
		} else {
			return ${::IxNetLegacy::_packageVersion}
		}
	}
}

proc ::ixNetLegacy {args} {
	if {[llength $args] == 0} {
		error "Unknown command"
	}

	set command {}
	foreach {arg} $args {
		if {[string first - $arg] == 0} {
			continue
		}
		set patternIndex [lsearch -glob $::IxNetLegacy::commandPatterns $arg]
		if {$patternIndex != -1} {
			set command [lindex $::IxNetLegacy::commandPatterns $patternIndex]
		}
		break
	}

	set ixNetCommand {}
	set first true
	foreach {arg} $args {
		if {$first} {
			set first false
			if {$arg != "ixNet" || $arg != "ixNetSecure" || $arg != "ixNetLegacy"} {
				append ixNetCommand "ixNet${::IxNetLegacy::BIN2}"
			}
		} else {
			append ixNetCommand ${::IxNetLegacy::BIN2}
		}

		if {[string length $arg] == 0} {
			append ixNetCommand "{}"
		} else {
			append ixNetCommand $arg
		}
	}

	switch -glob $command {
		"setDebug" {
            if {[llength $args] < 2} {
                error "missing required arguments"
            }
            return [::IxNetLegacy::SetDebug [lrange $args 1 end]]
        }
		"getRoot" {
			return {::ixNet::OBJ-/}
		}
		"getNull" {
			return {::ixNet::OBJ-null}
		}
		"connectiontoken" {
			return $::IxNetLegacy::_connectTokens
		}
		"connect" {
			set hostname [lindex $args 1]
			set port {8009}
			set sessionId {}
			set serverusername {}
			
			if {[llength $args] == 1} {
				error "ixNet connect <ipAddress> \[-port <8009>\] \[-version <5.30|5.40|5.50>\]"
			}

			array set argArray $args
			
			if {[info exists argArray(-port)]} {
				set port $argArray(-port)
			}
			set options "-clientusername $::tcl_platform(user) "
			if {[info exists argArray(-serverusername)]} {
				append options "-serverusername $argArray(-serverusername) "
				set serverusername $argArray(-serverusername)
			}
			if {[info exists argArray(-closeServerOnDisconnect)]} {
				append options "-closeServerOnDisconnect $argArray(-closeServerOnDisconnect) "
			} else {
				append options "-closeServerOnDisconnect true "
			}
            if {[info exists argArray(-connectTimeout)]} {
				append options "-connectTimeout $argArray(-connectTimeout) "
			}

 			if {[info exists argArray(-applicationVersion)]} {
				append options "-applicationVersion $argArray(-applicationVersion) "
			}
			if {[info exists argArray(-persistentApplicationVersion)]} {
				append options "-persistentApplicationVersion $argArray(-persistentApplicationVersion) "
			}
			if {[info exists argArray(-forceVersion)]} {
				append options "-forceVersion $argArray(-forceVersion) "
			}

			if {[info exists argArray(-sessionId)]} {
				append options "-sessionId $argArray(-sessionId) "
				set sessionId $argArray(-sessionId)
			}
			# this is in place to support the setting of this variable from high level perl
			# which uses an unsupported perl implementation, the returned value is a decorated
			# string that needs to be parsed and evaluated
			if {[info exists ::tcl_platform(IXNETWORK_CLIENT_TYPE)]} {
				set ::IxNetLegacy::_isClientTcl false
				append ixNetCommand "${::IxNetLegacy::BIN2}-clientType${::IxNetLegacy::BIN2}decorated"
			}
            set conRes [::IxNetLegacy::Connect $hostname $port $sessionId $serverusername $options $ixNetCommand]
            ::IxNetLegacy::CheckClientVersion
			set ::IxNetLegacy::_port $port
			return $conRes
		}
		"disconnect" {
			if {[catch {::IxNetLegacy::Disconnect $ixNetCommand} returnMessage]} {
				return "not connected"
			} else {
				return $returnMessage
			}
		}
		"getSessionInfo" {
			if {[::IxNetLegacy::IsConnected]} {
				set ret "id [::IxNetLegacy::GetSessionId] port $::IxNetLegacy::_port applicationType ixntcl state active inUse 1 backendType "
				if {$::IxNetLegacy::_proxySocketId != ""} {
					append ret "connectionmanager"
				} else {
					append ret "ixnetwork"
				}
			} else {
               	error  "not connected"
			}
		}
		"commit" {
			return [::IxNetLegacy::SendBuffer $ixNetCommand]
		}
		"readFrom" {
			# only bother with sending the file to the server if -ixNetRelative is not specified
			if {[lsearch -glob $args "-ixNetRelative"] == -1} {
				return [::IxNetLegacy::PutFileOnServer [lindex $args 1]]
			} else {
				return [::IxNetLegacy::SendBuffer $ixNetCommand]
			}
		}
		"writeTo" {
			# only bother with retrieving the file from the server if -ixNetRelative is not specified
			if {[lsearch -glob $args "-ixNetRelative"] == -1} {
				return [::IxNetLegacy::CreateFileOnServer [lindex $args 1]]
			} else {
				return [::IxNetLegacy::SendBuffer $ixNetCommand]
			}
		}
		"getVersion" {
			return [::IxNetLegacy::GetVersion]
		}
		"setSessionParameter" {
			if {[::IxNetLegacy::IsConnected]} {
				return [::IxNetLegacy::SendBuffer $ixNetCommand]
			} else {
				return [::IxNetLegacy::Buffer $ixNetCommand]
			}
		}
		"setA*" -
		"setM*" {
			return [::IxNetLegacy::Buffer $ixNetCommand]
		}
		default {
			return [::IxNetLegacy::SendBuffer $ixNetCommand]
		}
	}

}
