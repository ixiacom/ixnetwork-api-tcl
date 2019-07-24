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

set auto_path [linsert $auto_path 0 "[file join [file dirname [info script]] dependencies]"]

package req tls
package req http
package req json
package req websocket
package req logger

namespace eval ::IxNetSecure {
    variable commandPatterns {getApiKey getSessionInfo getRestUrl getSessions clearSession clearSessions getRoot getNull help connect disconnect setSessionParameter getVersion add commit readFrom writeTo exec* setA* setM* connectiontoken setDebug}
    variable _isClientTcl 1
    variable _debugFlag 0
    variable _connectionInfo {}
    variable _initialPort {}
    variable _initialHostname {}
    variable _headers {}
    variable _timeout 180000
    variable _webSocket {}
    variable _webSocketResponse
    variable _tclResult {}
    variable _evalResult {}
    variable _buffer {}
    variable _packageVersion "9.00.1915.16"
    variable _prefix {}
    variable _packageDirectory [file dirname [info script]]
    variable _transportType "WebSocket"
    variable _NoApiKey {00000000000000000000000000000000}
    variable OK {::ixNet::OK}
    variable ERROR {::ixNet::ERROR}
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
    variable _log [::logger::init [string trimleft [namespace current] ::]]
    ${_log}::setlevel emergency

    proc _tryReadAPIKey {dstFile} {
        set apiKeyValue 0
        if  { [catch {
            set fid [open $dstFile RDONLY]
            set apiKeyValue [read $fid]
            close $fid
        } err] } {
            return 0
        }
        return $apiKeyValue
    }
    proc _tryWriteAPIKey {dstFile key} {
        if { [catch {
            set fid [open $dstFile w+]
            puts -nonewline $fid $key
            close $fid
            
        } err ] } {
            return 0
        }
        return $dstFile

    }

    proc _parseUrl {url} {
        set result {verb https wsVerb wss port 443 socket No}
        dict set result url $url
        if {![regexp {(https?)://([^/]+):(\d+)} $url match verb hostname port]} {
            if {[regexp {(https?)://([^:/]+)} $url match verb hostname]} {
                if {$verb == "http"} {
                    set port 80
                } else {
                    set port 443
                }
            } else {
                error "Invalid url $url received in _parseUrl method"
            }
        }
        dict set result verb $verb
        dict set result port $port
        if {[regexp {\[(.*)\]} $hostname full_match exact_match]} {
            dict set result hostname $exact_match
        } else {
            dict set result hostname $hostname
        }
        if {$verb == "https"} {
            dict set result socket ::tls::socket
        } else {
            dict set result wsVerb "ws"
        }
        return $result
    }
    proc _getUrl {url args} {
        set result [eval ::IxNetSecure::_getUrlResult "\{$url\}" $args]
        set data   [dict get $result data]
        if {[dict exists $result error]} {
            error [dict get $result error]
        }
        return $data
    }


    proc _commandCallback {args} {
        ::IxNetSecure::Log "debug" "$args"
    }

    proc _checkTlsHandshake {hostname port} {
        set socket [::socket -async $hostname $port]
        fconfigure $socket -blocking 0
        ::tls::import $socket  -ssl3 false -ssl2 false -tls1 true -tls1.2 true  -tls1.1 true  -request false -require false  -command ::IxNetSecure::_commandCallback
        set tries 0
        set err {}
        while { $tries < 10 } {
            if {[catch {::tls::handshake $socket} err]} {
                if  {   [string first "No error" $err] != -1 || [string first "temporarily" $err] != -1} {
                    # No error or resource is temporarily unavailable - we need to continue
                    incr tries
                    after 1000
                    continue
                }
                if  { [string first "connection reset" $err] != -1 || [string first "wrong version number" $err] != -1 } {
                    close $socket 
                    set socket [::socket -async $hostname $port]
                    fconfigure $socket -blocking 1
                    ::tls::import $socket  -ssl3 false -ssl2 false -tls1 true -tls1.2 true  -tls1.1 true  -request false -require false  -command ::IxNetSecure::_commandCallback
                    if { ![catch {::tls::handshake $socket} err] } {
                        close $socket
                        ::IxNetSecure::Log "debug" "TLS handshake completed."
                        return 
                    }
                }
                close $socket
                ::IxNetSecure::Log "debug" "TLS handshake error: $err"
                error "TLS handshake failed : $err"
            }
            close $socket
            ::IxNetSecure::Log "debug" "TLS handshake completed."
            return 
        }
        ::IxNetSecure::Log "debug" "TLS handshake error: timeout"
        error "TLS handshake failed: timeout"
    }

    proc _getUrlResult {url args} {
        variable _timeout
        variable _headers
        variable _connectionInfo
        variable _packageVersion
        set parsedUrl [_parseUrl $url]
        set url [dict get $parsedUrl url]
        set hostname [dict get $parsedUrl hostname]
        set result {}
        set token {}
        set unregisterRequired 0
        set head 0
        if { [dict get $parsedUrl verb] == "https" && $_connectionInfo == {} } {
            set unregisterRequired 1
            ::http::register [dict get $parsedUrl verb] [dict get $parsedUrl port] [dict get $parsedUrl socket]
        } else {
            if  {  $_connectionInfo != {} && !([dict get $_connectionInfo verb] == [dict get $parsedUrl verb] &&
                  [dict get $_connectionInfo port] == [dict get $parsedUrl port]) } {
                error "Cannot access $url while connected to [dict get $_connectionInfo url]. Please disconnect first."
            }
        }
        if { [catch {
            set command "::http::geturl \{$url\} $args"
            if {$_headers != {} } {
                if {[string first "-type" $command] == -1} { 
                    set headers $_headers
                } else {
                    set headers "X-Api-Key [_tryGetAttr $_headers X-Api-Key $::IxNetSecure::_NoApiKey]"
                    dict set headers "IxNetwork-Lib" "IxNetwork tcl client v.$_packageVersion"
                }
                if {[_ip_encloser $hostname]} {
                    dict set headers "Host" "\[${hostname}\]"
                } else {
                    dict set headers "Host" ${hostname}
                }
                set command "$command -headers [list $headers]"
            }
            
             if { [string first "-validate" $command] != -1 } {
                set head 1
             }

            if { [string first "-timeout" $command] == -1 } {
                set command "$command -timeout $_timeout"
            }

            ::IxNetSecure::Log "debug" "$command"
            set token [eval $command]
        } err] } {
            ::http::cleanup $token
            if {$unregisterRequired} {
                ::http::unregister [dict get $parsedUrl verb]
            }
            ::IxNetSecure::Log "debug" "HTTP::error $err"
            set err [::IxNet::_TclCompatibilityError $hostname $err]
            error "CommunicationError: $err"
        }
        dict set result url $url
        dict set result status_code [::http::ncode $token]
        dict set result status [::http::status $token]
        if { [::http::status $token] == "ok"} {
            if { [string index [::http::ncode $token] 0] == "3"} {
                array set responseHeaders [::http::meta $token] 
                if {[info exists responseHeaders(Location)]} {
                    if { [string first "/" $responseHeaders(Location)] == 0} {
                        set url "[string range $url 0 [expr [string first / $url 8] - 1]]$responseHeaders(Location)"
                    } else {
                        set url $responseHeaders(Location)
                    }
                    ::IxNetSecure::Log "debug" "Following url $url"
                    ::http::cleanup $token
                    if {$unregisterRequired} {
                        ::http::unregister [dict get $parsedUrl verb]
                    }
                    unset result
                    return [eval ::IxNetSecure::_getUrlResult "\{$url\}" $args]
                }
            }
            dict set result data [::http::data $token]
            ::http::cleanup $token
            if {$unregisterRequired} {
                ::http::unregister [dict get $parsedUrl verb]
            }

            if {[dict get $result status_code] ==  {}} {
                ::IxNetSecure::Log "debug" "::http InternalServerError: No response from server"
                if {[dict get $result data] ==  {}} {
                    error "InternalServerError: No response from server"
                }
                error "InternalServerError: [dict get $result data]"
            }

            if {$head == 1 && [dict get $result status_code] == 405 } {
                dict set result status_code 204
            }

            if { [string index [dict get $result status_code] 0] != "2"} {
                set err [dict get $result data]
                if {![catch { set err [_jsonToDict $err] } ]} {
                    set err [_tryGetAttr $err error [_tryGetAttr $err errors]]
                }
                dict set result error "[dict get $result status_code]: $err"
                if { [dict get $result status_code] == "401" || [dict get $result status_code] == "403"} {
                    ::IxNetSecure::Log "debug" "::http response: IxNetAuthenticationError - $err"
                    error "IxNetAuthenticationError: $err"
                }
            }
            ::IxNetSecure::Log "debug" "::http response: [dict get $result status_code]"
            return $result 
        } else {
            # reset, timeout or error
            set msg "[dict get $result status] received while accessing $url." 
            if {[::http::status $token] == "error"} {
                set msg "${msg}\nError: [::http::error $token]"
            }
            ::http::cleanup $token
            if {$unregisterRequired} {
                ::http::unregister [dict get $parsedUrl verb]
            }
            error "ConnectionError: $msg"
        }
    }
    proc _restGetRedirect {url} {
        set headResult [::IxNetSecure::_getUrlResult $url -validate 1 -timeout 5000]
        set url [_fixUrl [dict get $headResult url]]
        return $url
    }
    proc _setConnectionInfo {inputArgs {store 0}}  {
        upvar $inputArgs argArray
        variable _initialPort
        variable _initialHostname
        variable _connectionInfo
        set initialPortUsed $argArray(-port) 
        if { $argArray(-port) == "auto"} {
            set params [list "https" 443]
        } else {
            set params [list "http" $argArray(-port) "https" $argArray(-port)]
        }
        foreach {verb port} $params {
            ::IxNetSecure::Log "debug" "trying connection to $verb port $port"
            if {[::IxNetSecure::_ip_encloser ${argArray(-ipAddress)}]} {
                set url "${verb}://\[$argArray(-ipAddress)\]:${port}/api/v1/sessions"
            } else {
                set url "${verb}://$argArray(-ipAddress):${port}/api/v1/sessions"
            }
            if {$verb == "https" && [catch {_checkTlsHandshake $argArray(-ipAddress) $port}]} {
                continue
            }
                        
            if { [catch  {set url [::IxNetSecure::_restGetRedirect $url]} err]} {
                if { [string first "IxNetAuthenticationError:" $err] == 0} {
                    error "The API key is either missing or incorrect."
                }
                continue
            }
            if {$store} {
                set _initialPort $argArray(-port)
                set _initialHostname  $argArray(-ipAddress)
                set _connectionInfo [::IxNetSecure::_parseUrl $url]
                ::IxNetSecure::Log "debug" "using $_connectionInfo"
                if { [dict get $_connectionInfo verb] == "https" } {
                    ::http::register [dict get $_connectionInfo verb] [dict get $_connectionInfo port] [dict get $_connectionInfo socket]
                }

            }
            set $argArray(-port) $port
            return $url
        }
         
        if {$initialPortUsed == "auto"} {
            set msg " using default ports (8009 or 443)"
        } else {
            set msg ":$initialPortUsed"
        }
        error "Unable to connect to $argArray(-ipAddress)$msg. Error: Host is unreachable."
    }
    proc _fixUrl {url} {
        set fixedUrl [lindex [split $url "?"] 0]
        set fixedUrl [lindex [split $fixedUrl "#"] 0]
        set fixedUrl [string trimright $fixedUrl "/"]
        return $fixedUrl
    }
    proc _getRestUrl  {} {
        variable _connectionInfo
        return [dict get $_connectionInfo restUrl]
    }
    proc _createHeaders {{apiKey ""} {apiKeyFile ""}} {
        variable _headers
        variable _packageVersion
        set apiKeyValue 0
        if { $apiKey != "" } {
            set apiKeyValue $apiKey
        } elseif { $apiKeyFile != "" } {
           if {[file pathtype $apiKeyFile] == "absolute"} {
               set apiKeyValue [_tryReadAPIKey $apiKeyFile]
           } else {
               set apiKeyValue [_tryReadAPIKey [file join [pwd] $apiKeyFile]] 
               if { $apiKeyValue == 0} { 
                   set apiKeyValue [_tryReadAPIKey [file join $::IxNetSecure::_packageDirectory $apiKeyFile]] 
               }
           }
        }

        if { $apiKeyValue == 0} { 
            set apiKeyValue $::IxNetSecure::_NoApiKey
        }  
        dict set _headers "X-Api-Key" "$apiKeyValue"
        dict set _headers "IxNetwork-Lib" "IxNetwork tcl client v.$_packageVersion"
        dict set _headers "Content-Type" "application/json"
        ::IxNetSecure::Log "debug" "_createHeaders $_headers"
    }

    proc _tryGetAttr {dict attr {defaultValue {}}} {
        if {[dict exists $dict $attr]} {
            return [dict get $dict $attr]
        } else {
            return $defaultValue
        }
    }

    proc _getDetailedSessionInfo {session {baseUrl {} } {port {}} } {
        variable _connectionInfo
        if { $baseUrl == {} } {
           set baseUrl [dict get $_connectionInfo url]
           set port [dict get $_connectionInfo port]
        } 
        set _sessionId [_tryGetAttr $session id -1]
        set sessionUrl "${baseUrl}/$_sessionId"
        set sessionIxNetworkUrl "${sessionUrl}/ixnetwork"
        set state [string tolower [dict get $session state]]
        set ixnet {isActive false connectedClients {} }
        if { $state == "active" } {
            set data [::IxNetSecure::_getUrl ${sessionIxNetworkUrl}/globals/ixnet  ]
            set ixnet [_jsonToDict $data]
        }
        set session_info {}

        set inUse [_tryGetAttr $ixnet isActive false]
        if { ![_parseAsBool $inUse] } {
            if {[string first "in use" [string tolower [_tryGetAttr $session subState]]] == 0} {
                    set inUse true
                } else {
                    set inUse false
                }
        }

        dict set session_info id $_sessionId
        dict set session_info url $sessionIxNetworkUrl
        dict set session_info sessionUrl $sessionUrl
        dict set session_info port $port 
        dict set session_info applicationType [_tryGetAttr $session "applicationType"]
        dict set session_info backendType [_tryGetAttr $session "backendType" "LinuxAPIServer"] 
        dict set session_info state $state
        dict set session_info subState [_tryGetAttr $session subState] 
        dict set session_info inUse $inUse
        dict set session_info userName [_tryGetAttr $session userName] 
        dict set session_info connectedClients [_tryGetAttr $ixnet connectedClients]
        dict set session_info createdOn [_tryGetAttr $session "createdOn"] 
        dict set session_info startedOn [_tryGetAttr $session "startedOn"] 
        dict set session_info stoppedOn [_tryGetAttr $session "stoppedOn"] 
        dict set session_info currentTime [_tryGetAttr $session "currentTime"]
        ::IxNetSecure::Log "debug" "Session Info for $session: $session_info"
        return $session_info
    }

    proc _waitForState {sessionUrl desiredState {timeout 450}} {
        ::IxNetSecure::Log "debug" "Waiting for $sessionUrl to reach $desiredState"
        set startTime [clock seconds]
        while {[expr [clock seconds] - $startTime] < $timeout } {
            set data [::IxNetSecure::_getUrl ${sessionUrl}]
            set session [_jsonToDict $data]
            set state [string tolower [dict get $session state]]
            switch -- $state {
                "active" {
                    if { [string tolower $desiredState] == "active"} {
                        return 1
                    }
                    if { [string tolower $desiredState] == "stopped" || \
                         [string tolower $desiredState] == "stopping"} {
                        break
                    }
                }
                "stopped" -
                "abnormallystopped"
                 {
                    if { [string tolower $desiredState] == "stopped"} {
                        return 1
                    }
                    if { [string tolower $desiredState] == "active" || \
                         [string tolower $desiredState] == "starting"} {
                        break
                    }
                }
                default {
                    if { [string tolower $desiredState] == $state } {
                        return 1
                    }
                }
            }
            after 1500
        }
        ::IxNetSecure::Log "debug" "Timeout occured while waiting for desired state $desiredState on $sessionUrl"
        error "Timeout occured while waiting for desired state $desiredState on $sessionUrl"
    }
    
    proc _deleteSession {sessionUrl} {
        catch { ::IxNetSecure::_getUrl $sessionUrl -method DELETE }
    }

    proc _stopSession {sessionUrl} {
        variable _connectionInfo
        catch { ::IxNetSecure::_getUrl "${sessionUrl}/operations/stop" -method POST }
        # if above return timeout (ixnet taking longer to stop) still wati to execute _waitForState
        # to allow gracefull shutdown (Windows)
        catch { ::IxNetSecure::_waitForState $sessionUrl "stopped" }
        # if above failed still try to DELETE session (forcefully)
        _deleteSession ${sessionUrl}
    }
    proc _clearSessions {inputArgs} {
        upvar $inputArgs argArray
        set deletedSessions {}
        set sessions [::IxNetSecure::_getSessions argArray]
        foreach {sessionId session} $sessions {
            set sessionUrl [dict get $session sessionUrl]
            if { [string tolower [_tryGetAttr $session backendType]] != "ixnetwork" && [_tryGetAttr $session state] == "active" && \
                [string first "in use" [string tolower [_tryGetAttr $session subState]]] != 0 && (![_parseAsBool [dict get $session inUse]])} {
                ::IxNetSecure::Log "debug" "Stopping $sessionUrl"
                ::IxNetSecure::_stopSession $sessionUrl
                lappend deletedSessions $sessionUrl
            }
        }
        return $deletedSessions
    }
    proc _clearSession {inputArgs} {
        variable ERROR
        upvar $inputArgs argArray
        set sessions [::IxNetSecure::_getSessions argArray]
        set session  [_tryGetAttr $sessions $argArray(-sessionId) ""]
        if {$session == ""} {
            error "Session $argArray(-sessionId) cannot be found in the list of sessions IDs: [join [dict keys $sessions] {,}]"
        }

        set force [_parseAsBool $argArray(-force)]
        set state [dict get $session state]
        set sessionUrl [dict get $session sessionUrl]
        set notInUse [expr ![_parseAsBool [dict get $session inUse]]]
        if {$force && $state == "initial"} {
            _getUrl "${sessionUrl}/operations/start" -type "application/json" -query {{"applicationType": "ixnetwork"}}
            _waitForState $sessionUrl "active"
            _stopSession $sessionUrl
            return $::IxNetSecure::OK
        } elseif {$state =="active"} {
            if {($force || $notInUse)} {
                if {[dict get $session backendType] == "ixnetwork"} {
                    return "Clearing IxNetwork standalone sessions is not supported."
                } elseif { [::IxNetSecure::IsConnected] && [_tryGetAttr $::IxNetSecure::_connectionInfo sessionId] == $argArray(-sessionId) } {
                    return [::IxNetSecure::Disconnect]
                } else {
                    _stopSession $sessionUrl
                    return $::IxNetSecure::OK
                }
            } else {
                return "Session $argArray(-sessionId) cannot be cleared as it is currently in $state state.\
                    Please specify -force true if you want to forcefully clear in use sessions."
            }
        } elseif {$force && $state == "stopped"} {
                _deleteSession $sessionUrl
                return $::IxNetSecure::OK
        }
        error "Session $argArray(-sessionId) cannot be cleared as it is currently in $state state"
    }

    proc _jsonToDict {data {isListRequest 0}} {
        if { [catch {
        if {$isListRequest} {
                set  jsonData [json::many-json2dict $data]
        } else {
                set jsonData [json::json2dict $data]
            }
        } err]} {
            error "Unexpected JSON: $err"
        }
        return $jsonData
    }
    proc _webSocketHandler {sock type msg} {
         switch -- $type {
            "error" -
            "close" {
                ::IxNetSecure::Log "debug" "websocket ${type} on ${sock} with content:${msg}"
                ::IxNetSecure::_close
            }
        }
        set ::IxNetSecure::_webSocketResponse $msg
    }

    proc _cleanupEnvironment {} {
        variable _debugFlag 0
        variable _connectionInfo {}
        variable _initialPort {}
        variable _initialHostname {}
        variable _headers {}
        variable _timeout 180000
        variable _webSocket {}
        variable _webSocketResponse
        variable _tclResult {}
        variable _evalResult {}
        variable _buffer {}
        set _connectionInfo  {}
        set _webSocket       {}
        set _headers         {}
        set _initialHostname {}
        set _initialPort     {}
        set _evalResult 1
        set _tclResult "connection closed"
        set _buffer {}
    }

    proc _close {{errorMessage {}} {sendStop 1}} {
        variable _connectionInfo
        variable _webSocket
        variable _headers
        variable _initialPort
        variable _initialHostname

        if {$_webSocket != {}} {
            ::IxNetSecure::Log "debug" "Closing websocket $_webSocket"
            catch {
                ::websocket::send $_webSocket 8 "[binary format Su 1000][encoding convertto utf-8 {Normal closure}]"
                ::websocket::Disconnect $_webSocket
            }
        }

        if {$_connectionInfo != {}} {
            if {[dict exists $_connectionInfo closeServerOnDisconnect] &&
                [dict exists $_connectionInfo sessionUrl] &&
                [_parseAsBool [dict get $_connectionInfo closeServerOnDisconnect]] &&
                ($sendStop == 1)} {
                 _stopSession [dict get $_connectionInfo sessionUrl]
            }

            if { [dict exists $_connectionInfo verb] && [dict get $_connectionInfo verb] == "https" } {
                    ::http::unregister [dict get $_connectionInfo verb]
            }
        }

        _cleanupEnvironment

        if {$errorMessage != {}} {
            error $errorMessage
        }

        return $::IxNetSecure::OK
    }

    proc _parseAsBool {str} {
        return [string is true -strict $str]
    }
    proc _getTclResult {} {
        variable _debugFlag
        variable _evalResult
        variable _tclResult

        update

        if {$_evalResult == 1} {
            error $_tclResult
        }
        ::IxNetSecure::Log "debug" "Received $_tclResult"
        if {!$::IxNetSecure::_isClientTcl} {
            set ::IxNetSecure::_parseResult $_tclResult
            ::IxNetSecure::_parseResult $_tclResult
            if {[string first "list" $::IxNetSecure::_parseResult] == 0} {
                return [eval $::IxNetSecure::_parseResult]
            } else {
                return $::IxNetSecure::_parseResult
            }
        } else {
            return $_tclResult
        }
    }
    proc _parseResult {ixNetResult} {
        set firstList 1
        set openReplacement "\[list"

        if {[string first "::ixNet::" $ixNetResult] == 0} {
            return
        }
        
        set ixNetResult [string map [list "\{\}" "[binary format "c" 2][binary format "c" 3]"] $ixNetResult]
        while {1} {
            set openBrace [string first "\{" $ixNetResult]
            if {$openBrace == -1} {
                break
            }

            # remove next additional side by side open brace and it's corresponding close brace
            while {[string index $ixNetResult [expr $openBrace + 1]] == "\{"} {
                set closeBrace [_findNextClosingBrace $ixNetResult $openBrace]
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
            set closeBrace [_findNextClosingBrace $ixNetResult $openBrace]
            
            set openReplacement ""
            set closeReplacement ""
            switch $datatype {
                "kArray" -
                "kStruct" {
                    if {$firstList} {
                        set openReplacement "list "
                        set firstList 0
                    } else {
                        set openReplacement "\[list "
                        set closeReplacement "\]"
                    }
                }
                default {
                    if {!$firstList && [string first " " [string range $ixNetResult $openBrace $closeBrace]] != -1} {
                        set openReplacement [binary format "c" 2]
                        set closeReplacement [binary format "c" 3]
                    }
                }
            }
            set ixNetResult [string replace $ixNetResult $openBrace $comma $openReplacement]
            set closeBrace [expr $closeBrace - (($comma - $openBrace) - [string length $openReplacement]) - 1]
            set ixNetResult [string replace $ixNetResult $closeBrace $closeBrace $closeReplacement]
        }
        set ::IxNetSecure::_parseResult [string map [list [binary format "c" 2] "\{" [binary format "c" 3] "\}"] $ixNetResult]
        if {$::IxNetSecure::_parseResult == "{}" } {set ::IxNetSecure::_parseResult ""}
    }
    proc _getConnectionToken {} {
        if {![::IxNetSecure::IsConnected]} {
            error "not connected."
        }
        set connectionToken {}
        if {[string tolower [_tryGetAttr $::IxNetSecure::_connectionInfo backendType]] == "connectionmanager"} {
            dict set connectionToken "-sessionid"               [_tryGetAttr $::IxNetSecure::_connectionInfo sessionId]
            dict set connectionToken "-serverusername"          [_tryGetAttr $::IxNetSecure::_connectionInfo serverusername]
            dict set connectionToken "-port"                    [_tryGetAttr $::IxNetSecure::_connectionInfo port] 
            dict set connectionToken "-starttime"               [_tryGetAttr $::IxNetSecure::_connectionInfo startTime]
            dict set connectionToken "-host"                    [_tryGetAttr $::IxNetSecure::_connectionInfo hostname]
            dict set connectionToken "-closeServerOnDisconnect" [string totitle [_tryGetAttr $::IxNetSecure::_connectionInfo closeServerOnDisconnect]]
            dict set connectionToken "-state"                   "active"
            foreach {key} [list "tclPort" "restPort" "processId"] {
                dict set connectionToken "-[string tolower $key]"                [_tryGetAttr $::IxNetSecure::_connectionInfo $key]
            }
        }
        return $connectionToken
    }
    proc _findNextClosingBrace {value {startPos 0}} {
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
    proc _buffer {command} {
        append ::IxNetSecure::_buffer $command
        append ::IxNetSecure::_buffer $::IxNetSecure::BIN3

        return $::IxNetSecure::OK
    }
    proc _sendBuffer {command} {
        append ::IxNetSecure::_buffer $command
        append ::IxNetSecure::_buffer $::IxNetSecure::BIN3

        return [::IxNetSecure::Send $::IxNetSecure::_buffer]
    }
    proc _isSessionAvailable {session {rasiseError 1}} {
        variable ERROR
        set detailedSessionInfo [_getDetailedSessionInfo $session]
        if { [_parseAsBool [dict get $detailedSessionInfo inUse]] } {
            if { $rasiseError == 1} {
                error "The requested session is currently in use."
            }
            return 0
        }
        return 1
    }
    proc _getSessions {args {fromConnect false}} {
        variable _initialPort
        variable _initialHostname
        variable _connectionInfo
        upvar $args argArray
        if {![::IxNetSecure::IsConnected]} {
            if {$fromConnect} {
                set baseURL [_tryGetAttr $_connectionInfo url]
                set port  [_tryGetAttr $_connectionInfo port]
            } else {
                ::IxNetSecure::_createHeaders $argArray(-apiKey) $argArray(-apiKeyFile)
                set baseURL [::IxNetSecure::_setConnectionInfo argArray]
                set port $argArray(-port)
            } 
        } else {
            if { (${argArray(-ipAddress)} != $_initialHostname && ${argArray(-ipAddress)} != [_tryGetAttr $_connectionInfo hostname]) || \
                 (${argArray(-port)} != $_initialPort && ${argArray(-port)} !=  [_tryGetAttr $_connectionInfo port]) } {
                error "A connection has already been established to [_tryGetAttr $_connectionInfo hostname]:[_tryGetAttr $_connectionInfo port].\
                    In order to query ${argArray(-ipAddress)}:${argArray(-port)} you must first disconnect."
            }
            if {[::IxNetSecure::_ip_encloser ${argArray(-ipAddress)}]} {
                set baseURL "https://\[${argArray(-ipAddress)}\]:${argArray(-port)}/api/v1/sessions"    
            } else {
                set baseURL "https://${argArray(-ipAddress)}:${argArray(-port)}/api/v1/sessions"
            }
            set port $argArray(-port)
        }
        if {[catch {
            set data [::IxNetSecure::_getUrl $baseURL]
            set response [::IxNetSecure::_jsonToDict $data]
        } err]} {
            error "Unable to connect to ${argArray(-ipAddress)}:${argArray(-port)}. Error: $err"
        }
        set sessionList {}
        set result {}
        foreach session $response {
            if {[dict get $session "applicationType"] == "ixnrest" || \
                    [string tolower [_tryGetAttr $session backendType "LinuxAPIServer"]] == "ixnetwork"} {
                set detailSessionInfo [::IxNetSecure::_getDetailedSessionInfo $session $baseURL $port]
                dict set result [_tryGetAttr $session id -1] $detailSessionInfo 
            }
        }
        ::IxNetSecure::Log "debug" "GetSessions returned $result"
        return $result  
    }
    proc _getSessionInfo {} {
        variable _connectionInfo
        set data [::IxNetSecure::_getUrl [dict get $_connectionInfo sessionUrl]]
        set session [::IxNetSecure::_jsonToDict $data]
        return [::IxNetSecure::_getDetailedSessionInfo $session]
    }

    proc _putFileOnServer {filename} {
        variable _connectionInfo
        variable BIN2
        variable STX
        variable READFROM
        variable FILENAME
        variable CONTENTLENGTH
        variable CONTENT

        set data [::IxNetSecure::_getUrl "[_getRestUrl]/files" ]
        set absolute [dict get [_jsonToDict $data] absolute]
        set localFilename [file tail [string map {"\\" "/"} $filename]]
        set remoteFilename [string map {"\\" "/"} "$absolute/$localFilename"]
        ::IxNetSecure::Log "debug" "Uploading $localFilename..."
        
        set fid [open $filename RDONLY]
        fconfigure $fid -buffering full -encoding binary -translation binary
        set data [::IxNetSecure::_getUrl "[_getRestUrl]/files?[::http::formatQuery filename ${localFilename}]" -type "application/octet-stream" -querychannel $fid]
        close $fid

        return [::IxNetSecure::Send "ixNet${BIN2}readFrom${BIN2}${remoteFilename}${BIN2}-ixNetRelative"]
    }
    proc _createFileOnServer {filename} {
        variable _connectionInfo
        variable BIN2
        variable STX
        variable WRITETO
        variable FILENAME
        variable CONTENT
        set localFilename $filename
        set filename [file tail [string map {"\\" "/"} "$filename"]]
        set data [::IxNetSecure::_getUrl "[_getRestUrl]/files"]
        set absolute [dict get [_jsonToDict $data] absolute]
        set remoteFilename [string map {"\\" "/"} "$absolute/$filename"]
        set data [::IxNetSecure::_getUrl "[_getRestUrl]/files?[::http::formatQuery filename ${filename}]" -type "application/octet-stream" -query "0"]
        return [::IxNetSecure::Send "ixNet${BIN2}writeTo${BIN2}${remoteFilename}${BIN2}-ixNetRelative${BIN2}-remote${BIN2}${localFilename}${BIN2}-overwrite"]
    }

    proc _ip_encloser { ip_address } {
        if {[string match "*:*" $ip_address]} {
            return 1
        } else {
            return 0
        }
    }

    proc Connect {args} {
        upvar $args argArray
        
        variable _initialPort
        variable _initialHostname
        variable _connectionInfo
        variable _headers
        variable ERROR
        variable BIN2

        # set up the headers with the apiKey
        ::IxNetSecure::_createHeaders $argArray(-apiKey) $argArray(-apiKeyFile)
        ::IxNetSecure::_setConnectionInfo argArray 1
        # set up the secure socket
        set result {}
        set restPrefix [dict get $_connectionInfo verb]
        set wsPrefix [dict get $_connectionInfo wsVerb]
        set port [dict get $_connectionInfo port]
        if {[::IxNetSecure::_ip_encloser ${argArray(-ipAddress)}]} {
            set rootUrlPrefix "${restPrefix}://\[${argArray(-ipAddress)}\]:${port}/api/v1/sessions"
        } else {
            set rootUrlPrefix "${restPrefix}://${argArray(-ipAddress)}:${port}/api/v1/sessions"
        }
        
        # create a session if a valid sessionId has not been specified
        if { [catch {
            if {$argArray(-sessionId) < 1 && $argArray(-serverusername) == ""} {
                set data [::IxNetSecure::_getUrl $rootUrlPrefix -type "application/json" -query {{"applicationType": "ixnrest"}} -timeout [expr 1000 * $argArray(-connectTimeout)]]
                set session [_jsonToDict $data]
            } else {
                set sessions [::IxNetSecure::_getSessions args true]
                if { $argArray(-serverusername) != ""} {
                    set matched_sessions {}
                    foreach {id session} $sessions {
                        if {[string tolower [_tryGetAttr $session userName]] == [string tolower $argArray(-serverusername)]} {
                            dict set matched_sessions $id $session
                        }
                    }
                    set sessions $matched_sessions
                
                    if {$sessions == {}} {
                        error "There are no sessions available with the serverusername $argArray(-serverusername)"
                    }
                    if {$argArray(-sessionId) < 1}  {
                        if { [llength [dict keys $sessions]] > 1 } {
                            error "There are multiple sessions available with the serverusername $argArray(-serverusername). Please specify -sessionId also."    
                        } else {
                            set argArray(-sessionId) [lindex [dict keys $sessions] 0]
                        }
                    }
                }

                if { [lsearch [dict keys $sessions] $argArray(-sessionId)] == -1} {
                    error "Invalid sessionId value ($argArray(-sessionId))."
                }

                set session [dict get $sessions $argArray(-sessionId)]
                if {[_tryGetAttr $session inUse]} {
                    if { [string tolower [_tryGetAttr $session backendType]] == "connectionmanager" ||[_parseAsBool $argArray(-allowOnlyOneConnection)]} {
                        error "The requested session is currently in use."
                    }
                    puts "WARNING: you are connecting to session [dict get $session id] which is in use."
                }
            }
            set _sessionId [_tryGetAttr $session id -1]
            set _sessionUrl "${rootUrlPrefix}/${_sessionId}"
            dict set _connectionInfo url ${rootUrlPrefix}
            dict set _connectionInfo sessionId $_sessionId
            dict set _connectionInfo sessionUrl $_sessionUrl
            dict set _connectionInfo backendType [_tryGetAttr $session backendType "LinuxAPIServer"] 
            dict set _connectionInfo serverusername [_tryGetAttr $session userName "Unknown"] 
            dict set _connectionInfo startTime [clock format [clock seconds] -format "%Y%m%d_%X"]

            if {$argArray(-closeServerOnDisconnect) == "auto"} {
                if { [_tryGetAttr $session applicationType] == "ixnrest"} {
                    set argArray(-closeServerOnDisconnect) "true"
                } else {
                    set argArray(-closeServerOnDisconnect) "false"
                }
            } else {
                if { [_parseAsBool $argArray(-closeServerOnDisconnect) ] } { 
                    set argArray(-closeServerOnDisconnect) "true"
                } else {
                    set argArray(-closeServerOnDisconnect) "false"
                }
            }
            dict set _connectionInfo closeServerOnDisconnect $argArray(-closeServerOnDisconnect)

            if {[string tolower [dict get $session state]] == "initial" || [string tolower [dict get $session state]] == "stopped"} {
                ::IxNetSecure::_getUrl "${_sessionUrl}/operations/start" -type "application/json" -query {{"applicationType": "ixnetwork"}}
            }

            # wait connectTimeout seconds for the session to go active
            if {[catch {_waitForState $_sessionUrl "active" $argArray(-connectTimeout)}]} {
                _deleteSession ${_sessionUrl}
                error "IxNetwork instance ${_sessionId} did not start within $argArray(-connectTimeout) seconds."
            }

            if { [_parseAsBool ${argArray(-allowOnlyOneConnection)}]} {
                _isSessionAvailable $session 1
            }

            set _restUrl "${_sessionUrl}/ixnetwork"
            if {[::IxNetSecure::_ip_encloser ${argArray(-ipAddress)}]} {
                set _wsUrl "${wsPrefix}://\[${argArray(-ipAddress)}\]:${port}/ixnetworkweb/ixnrest/ws/api/v1/sessions/${_sessionId}/ixnetwork/globals/ixnet?closeServerOnDisconnect=${argArray(-closeServerOnDisconnect)}&[::http::formatQuery clientType ${argArray(-clientType)}]&[::http::formatQuery clientUsername ${argArray(-clientusername)}]"
            } else {
                set _wsUrl "${wsPrefix}://${argArray(-ipAddress)}:${port}/ixnetworkweb/ixnrest/ws/api/v1/sessions/${_sessionId}/ixnetwork/globals/ixnet?closeServerOnDisconnect=${argArray(-closeServerOnDisconnect)}&[::http::formatQuery clientType ${argArray(-clientType)}]&[::http::formatQuery clientUsername ${argArray(-clientusername)}]"
            }
            dict set _connectionInfo restUrl $_restUrl
            dict set _connectionInfo wsUrl $_wsUrl
            ::IxNetSecure::Log "debug" "Connection Info: $_connectionInfo"
            set ::websocket::WS(maxlength) 1073741824
            set ::IxNetSecure::_webSocket [::websocket::open $_wsUrl ::IxNetSecure::_webSocketHandler]
            vwait ::IxNetSecure::_webSocketResponse
            if { ![::IxNetSecure::IsConnected] } {
                error $::IxNetSecure::_webSocketResponse              
            }

            set connect "ixNet${BIN2}connect${BIN2}"
            append connect "-clientType${BIN2}${argArray(-clientType)}${BIN2}"
            append connect "-clientId${BIN2}${argArray(-clientId)}${BIN2}"
            append connect "-version${BIN2}${argArray(-version)}${BIN2}"
            append connect "-clientUsername${BIN2}${argArray(-clientusername)}${BIN2}"
            append connect "-closeServerOnDisconnect${BIN2}${argArray(-closeServerOnDisconnect)}${BIN2}"
            append connect "-apiKey${BIN2}[_tryGetAttr $_headers X-Api-Key $::IxNetSecure::_NoApiKey]"
            set result [::IxNetSecure::Send $connect]
            set sessionParams [::IxNetSecure::Send "ixNet${BIN2}setSessionParameters${BIN2}"]
            foreach {key} [list "tclPort" "restPort" "processId"] {
                dict set _connectionInfo $key [_tryGetAttr $sessionParams $key]
            }

            if { [string tolower [_tryGetAttr $_connectionInfo backendType]] == "connectionmanager"} {
                puts "connectiontoken is [::IxNetSecure::_getConnectionToken]"; update
            }
            ::IxNetSecure::CheckClientVersion
        } err]} {
            if {$_initialPort == "auto"} {
                set msg ":443"
            } else {
                set msg ":$_initialPort"
            }
            ::IxNetSecure::_close
            _cleanupEnvironment
            error "Unable to connect to $argArray(-ipAddress)$msg. Error: $ERROR: $err"
        }
        return $result
    }    

    proc Log {level args} {
        variable _log
        if {[string length $args] > 1024} {
            ${_log}::${level} "[string range $args 0 1024]..."
        } else {
            ${_log}::${level} $args
        }
    }

    proc SetDebug {flag} {
        return [::IxNetSecure::SetLoggingLevel $flag]
    }

    proc SetLoggingLevel {level} {
        variable _log
        set levels {emergency debug info notice warn error critical alert}
        if {![regexp $level $levels]} {
            if {[string is boolean $level]} {
                set level [_parseAsBool $level]
            }

            if  {[string is digit $level]} {
                set level [lindex $levels $level]
            } else {
                set level "emergency"
            }
        }
        if {$level == ""} {
            set level "emergency"
        }
        
        ${_log}::setlevel [::websocket::loglevel $level]
        return $::IxNetSecure::OK
    }

    proc CheckClientVersion {} {
        set serverVersion [ixNetSecure getVersion]
        if { ${::IxNetSecure::_packageVersion} != $serverVersion} {
            puts "WARNING: IxNetwork TCL library version ${::IxNetSecure::_packageVersion} does not match the IxNetwork server version $serverVersion"
        }
    }

    proc IsConnected {} {
        variable _webSocket
        if { $_webSocket != {} } {
            return 1
        } else {
            return 0
        }
    }

    proc GetApiKey {args} {
        upvar $args argArray 
        if {[::IxNetSecure::IsConnected] == 0} {
                ::IxNetSecure::_createHeaders
        }
        if {[::IxNetSecure::_ip_encloser ${argArray(-ipAddress)}]} {
            set url "https://\[$argArray(-ipAddress)\]:$argArray(-port)/api/v1/auth/session"
        } else {
            set url "https://$argArray(-ipAddress):$argArray(-port)/api/v1/auth/session"
        }
        set payload "{\"username\": \"$argArray(-username)\", \"password\": \"$argArray(-password)\"}"
        
        if { [catch {
                set data [::IxNetSecure::_getUrl $url -type "application/json" -query $payload -timeout 180000]
                set credentials [_jsonToDict $data]
        } err] } {
            if { [string first "IxNetAuthenticationError:" $err] >= 0} {
                error "Unable to get API key from $argArray(-ipAddress):$argArray(-port). Error: $err\n\
                        Please check the getApiKey command arguments. \n\
                        An example of a correct method call is: \n\t\
                            ixNet getApiKey <hostname> -username <admin> -password <admin> \[-port <443>\] \[-apiKeyFile <api.key>\]"
            }
            error "Unable to get API key from $argArray(-ipAddress):$argArray(-port)."
        }
   
        if { [dict exists $credentials apiKey] } {
            set apiKey [dict get $credentials apiKey]
            set apiKeyFile $argArray(-apiKeyFile)
            ::IxNetSecure::_createHeaders $apiKey

            if {[file pathtype $apiKeyFile] == "absolute"} {
                set apiKeyPath [_tryWriteAPIKey $apiKeyFile $apiKey]
            } else {
                set apiKeyPath [_tryWriteAPIKey [file join [pwd] $apiKeyFile] $apiKey] 
                if { $apiKeyPath == 0} { 
                    set apiKeyPath [_tryWriteAPIKey [file join $::IxNetSecure::_packageDirectory $apiKeyFile] $apiKey] 
                }
            }
            if {$apiKeyPath == 0} { 
                ::IxNetSecure::Log "debug" "Could not save API key to disk."
            } else {
                ::IxNetSecure::Log "debug" "The API key was saved at: $apiKeyPath."
            }
            return $apiKey
        } else {
            error "Unable to get API key from $argArray(-ipAddress). Error: $credentials"
        }
   }
    proc Disconnect {} {
        if {[::IxNetSecure::IsConnected]} {
            set errmsg   {}
            set sendStop 0
            return [::IxNetSecure::_close $errmsg $sendStop]
        } else {
            _cleanupEnvironment
            return "not connected"
        }

    }

    proc Send {command} {
        variable STX
        variable IXNET
        variable CONTENT
        variable ERROR
        ::IxNetSecure::Log "debug" "Sending $command"
        
        set code [catch {
            set sent [::websocket::send $::IxNetSecure::_webSocket "binary" "<$STX><$IXNET><$CONTENT[string length $command]>$command"]
            if {$sent != -1} {
                vwait ::IxNetSecure::_webSocketResponse
            } else {
                error "could not send to remote end"
            }
        } returnValue]
        set ::IxNetSecure::_buffer {}
        if {$code == 1} {
            ::IxNetSecure::_close
            error "$ERROR: Connection to the remote IxNetwork instance has been closed: $returnValue"
        } else {
            if {[catch {::IxNetSecure::Read $::IxNetSecure::_webSocketResponse} err]} {
                error "$ERROR: $err"
            }
            return [::IxNetSecure::_getTclResult]
        }
    }

    proc Read {receiveBuffer} {
        variable _connectionInfo
        variable _tclResult
        variable _evalResult
        variable _debugFlag
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
        while {[string length $receiveBuffer] > 0} {
            set startIndex -1
            set stopIndex -1
            set commandId ""
            set contentLength 0

            set startIndex [string first $STARTINDEX $receiveBuffer]
            set stopIndex [string first $STOPINDEX $receiveBuffer]
            if {$startIndex != -1 && $stopIndex != -1} {
                set commandId [string range $receiveBuffer [expr $startIndex + 1] [expr $startIndex + 3]]

                if {[expr $startIndex + 4] < $stopIndex} {
                    set contentLength [string range $receiveBuffer [expr $startIndex + 4] [expr $stopIndex - 1]]
                }
            } else {
                break
            }

            switch -- $commandId {
                "001" {
                    set ::IxNetSecure::_evalResult $TCL_ERROR
                    set ::IxNetSecure::_tclResult {}
                }
                "004" {
                    set _evalResult [string range $receiveBuffer [expr $stopIndex + 1] [expr $stopIndex + $contentLength]]
                }
                "007" {
                    set filename [string range $receiveBuffer [expr $stopIndex + 1] [expr $stopIndex + $contentLength]]
                    set remoteFilename [file tail [string map {"\\" "/"} "$filename"]]

                    ::IxNetSecure::Log "debug" "Downloading ${remoteFilename}..."
                    
                    if {[catch {file mkdir [file dirname $filename]} errorMessage]} {
                        error "unable to create directory [file dirname $filename]"
                    }
                    if {[catch {set fid [open $filename wb]} errorMessage]} {
                        error "unable to create file $filename $errorMessage"
                    }
                    fconfigure $fid -translation binary
                    set data [::IxNetSecure::_getUrl "[_getRestUrl]/files?[::http::formatQuery filename ${remoteFilename}]" -channel $fid -binary 1]
                    close $fid
                }
                "009" {
                    set ::IxNetSecure::_tclResult [string range $receiveBuffer [expr $stopIndex + 1] [expr $stopIndex + 1 + $contentLength]]
                }
                default {
                }
            }

            if {[string length $receiveBuffer] <= [expr $stopIndex + $contentLength + 1]} {
                set receiveBuffer {}
            } else {
                set receiveBuffer [string range $receiveBuffer [expr $stopIndex + $contentLength + 1] [string length $receiveBuffer]]
            }
        }
    }




    proc Usage {command {errorMessage {}}} {
        
        set throwError 0
        if {[string length $errorMessage] > 0} {
            set message "Invalid usage of command $command: $errorMessage \n\n"
            set throwError 1
        }

        switch $command {
            "clearSession" -
            "clearSessions" {
                append message "usage: ixNet $command <hostname>  -apiKey | -apiKeyFile\n \
                    \tAllows to stop the session(s) which are no longer in use.\n\n \
                    required:\n \
                    \t<hostname>    Hostname or ipaddress of the IxNetwork session manager.\n \
                    optional:\n \
                    \t-port <443>   The target port for the connection. The default value is 443.\n \
                    \t-apiKey       The value returned by ixNet getApiKey used to authenticate calls to the IxNetwork instance.\n \
                    \t-apiKey       File The filename created by ixNet getApiKey. The default value is api.key\n"
                    if { $command == "clearSession"} {
                        append message "\t-sessionId       Used to specify the session id to be cleared.\
                                    Use ixNet getSessions for a list of valid sessions.\n \
                            \t-force       Boolean value.This parameter instructs the library to ignore \
                                    whether this session is Active or In Use and close it forcefully.\
                                    This will close any sessions which might have ended up in a unresponsive state. \
                                    It will also close sessions belonging to another user.\
                                    The default value is false\n"
                    }
            }
            "getSessions" {
                append message "usage: ixNet $command <hostname>  -apiKey | -apiKeyFile\n \
                    \tGet a list of sessions\n\n \
                    required:\n \
                    \t<hostname>    Hostname or ipaddress of the IxNetwork session manager.\n \
                    optional:\n \
                    \t-port <443>   The target port for the connection. The default value is 443.\n \
                    \t-apiKey       The value returned by ixNet getApiKey used to authenticate calls to the IxNetwork instance.\n \
                    \t-apiKey       File The filename created by ixNet getApiKey. The default value is api.key\n"
            }
            "connect" {
                append message "usage: ixNet connect <hostname>\n \
                    \tEstablish a connection to an instance of IxNetwork\n\n \
                    required:\n \
                    \t<hostname>    Hostname or ipaddress of the IxNetwork instance or connection manager instance.\n \
                    optional:\n \
                    \t-port         The target port for the connection. The default value is 443, however if 443 is unreachable port 11009 will be tried.\n \
                    \t-sessionId    Used to connect to an existing session by specifying the session id. Use ixNet getSessions for a list of valid sessions.\n \
                    \t-serverusername  Used to connect to an existing session by specifying the username. Use ixNet getSessions for a list of valid sessions \n\
                    \t-version <5.30>  The version of the IxNetwork session.\n \
                    \t-connectTimeout <450>  The amount of time in seconds before the connection attempt times out.\n \
                    \t-apiKey  The value returned by ixNet getApiKey used to authenticate calls to the IxNetwork instance.\n \
                    \t-apiKeyFile The filename created by ixNet getApiKey.\n
                    Please refer to IxNetwork documentation for all other possible arguments.\n"
            }
            "getApiKey" {
                append message "usage: ixNet getApiKey <hostname> -username <uid> -password <pwd>\n \
                    \tGet an api key used to verify requests to an IxNetwork instance\n\n \
                    required:\n \
                    \t<hostname>    Hostname or ipaddress of the authenticating host.\n \
                    \t-username     Username\n \
                    \t-password     Password\n \
                    optional:\n \
                    \t-port         The target port for the connection. The default value is 443.\n \
                    \t-apiKeyFile <api.key> Api key returned by this call will also be written to this file\n"
            }
        }

        if {$throwError} {
            error $message
        } else {
            puts $message
        }
    }
}

proc ::ixNetSecure {args} {
    if {[llength $args] == 0} {
        error "Unknown command"
    }
    set command {}
    foreach {arg} $args {
        if {[string first - $arg] == 0} {
            continue
        }
        set patternIndex [lsearch -glob $::IxNetSecure::commandPatterns $arg]
        if {$patternIndex != -1} {
            set command [lindex $::IxNetSecure::commandPatterns $patternIndex]
        }
        break
    }

    set ixNetCommand {}
    set first 1
    foreach {arg} $args {
        if {$first} {
            set first 0
            if {$arg != "ixNet" || $arg != "ixNetSecure" || $arg != "ixNetLegacy"} {
                append ixNetCommand "ixNet[binary format "c" 2]"
            }
        } else {
            append ixNetCommand [binary format "c" 2]
        }

        if {[string length $arg] == 0} {
            append ixNetCommand "{}"
        } else {
            append ixNetCommand $arg
        }
    }

    switch $command {
        "getApiKey" -
        "clearSession" -
        "clearSessions" -
        "getSessions" -
        "getRoot" -
        "getNull" -
        "getVersion" -
        "setSessionParameter" -
        "disconnect" -
        "setDebug" -
        "connect" {
            # do nothing
        }
        default {
            if {[::IxNetSecure::IsConnected] == 0} {
                return [::IxNetSecure::_close "not connected"]
            }
        }
    }
    
    switch -glob $command {
        "setDebug" {
            if {[llength $args] < 2} {
                error "missing required arguments"
            }
            return [::IxNetSecure::SetDebug [lrange $args 1 end]]
        }
        "connectiontoken" {
            return [::IxNetSecure::_getConnectionToken]
        }
        "getApiKey" {
            set code [catch {
                if {[llength $args] < 2} {
                    error "SyntaxError: This method requires at least the hostname argument. \
                            An example of a correct method call is: \n\t\
                            ixNet getApiKey <hostname> -username <admin> -password <admin> [-port <443>] [-apiKeyFile <api.key>]"
                }
                array set argArray [lrange $args 2 end]
                set argArray(-ipAddress) [lindex $args 1]
                array set defaultArgs {
                    -apiKeyFile api.key
                    -port       443
                    -username   {}
                    -password   {}
                }
                foreach {key value} [array get defaultArgs] {
                    if {[info exists argArray($key)] != 1} {
                        set argArray($key) $value
                    }
                }
            } returnValue]
            if {$code == 1} {
                return [::IxNetSecure::Usage $command $returnValue]
            } else {        
                return [::IxNetSecure::GetApiKey argArray]
            }
        }
        "clearSession" {
            set code [catch {
                if {[llength $args] < 2} {
                    error "missing required arguments"
                }
                array set argArray [lrange $args 2 end]
                set argArray(-ipAddress) [lindex $args 1]
                array set defaultArgs {
                    -apiKey     {} 
                    -apiKeyFile api.key
                    -port       443
                    -force      false
                }
                foreach {key value} [array get defaultArgs] {
                    if {[info exists argArray($key)] != 1} {
                        set argArray($key) $value
                    }
                }
                
                if {![info exists argArray(-sessionId)]} {
                    error "A session ID must be provided in order to clear a specific session."
                }
                
            } returnValue]
            if {$code == 1} {
                return [::IxNetSecure::Usage $command $returnValue]
            } else {
                return [::IxNetSecure::_clearSession argArray]
            }
        }
        "clearSessions" {
            set code [catch {
                if {[llength $args] < 2} {
                    error "missing required arguments"
                }
                array set argArray [lrange $args 2 end]
                set argArray(-ipAddress) [lindex $args 1]
                array set defaultArgs {
                    -apiKey     {} 
                    -apiKeyFile api.key
                    -port       443
                }
                foreach {key value} [array get defaultArgs] {
                    if {[info exists argArray($key)] != 1} {
                        set argArray($key) $value
                    }
                }
                
            } returnValue]
            if {$code == 1} {
                return [::IxNetSecure::Usage $command $returnValue]
            } else {
                return [::IxNetSecure::_clearSessions argArray]
            }
        }
        "getSessionInfo" {
            return [::IxNetSecure::_getSessionInfo]
        }
        "getRestUrl" {
            return [::IxNetSecure::_getRestUrl]
        }
        "getSessions" {
            set code [catch {
                if {[llength $args] < 2} {
                    error "missing required arguments"
                }
                array set argArray [lrange $args 2 end]
                set argArray(-ipAddress) [lindex $args 1]
                array set defaultArgs {
                    -apiKey     {} 
                    -apiKeyFile api.key
                    -port       443
                }
                foreach {key value} [array get defaultArgs] {
                    if {[info exists argArray($key)] != 1} {
                        set argArray($key) $value
                    }
                }
            } returnValue]
            if {$code == 1} {
                return [::IxNetSecure::Usage $command $returnValue]
            } else {
                return [::IxNetSecure::_getSessions argArray]
            }
        }
        "getRoot" {
            return {::ixNet::OBJ-/}
        }
        "getNull" {
            return {::ixNet::OBJ-null}
        }
        "connect" {

                if {[llength $args] < 2} {
                    return [::IxNetSecure::Usage $command "missing required arguments"]
                }

                array set argArray [lrange $args 2 end]
                set argArray(-ipAddress) [lindex $args 1]
                set argArray(-clientType) "tcl"
                if {[info exists ::tcl_platform(IXNETWORK_CLIENT_TYPE)]} {
                    set ::IxNetSecure::_isClientTcl 0
                    set argArray(-clientType) "decorated"
                }

                array set defaultArgs {
                    -port auto
                    -sessionId 0 
                    -clientId tcl
                    -version 5.30 
                    -connectTimeout 450
                    -allowOnlyOneConnection false
                    -apiKey {} 
                    -apiKeyFile api.key
                    -closeServerOnDisconnect auto 
                    -product ixnrest
                    -clientusername {}
                    -serverusername {}
                }
                
                
                set defaultArgs(-clientusername) $::tcl_platform(user)
                foreach {key value} [array get defaultArgs] {
                    if {[info exists argArray($key)] != 1} {
                        set argArray($key) $value
                    }
                }

                if {[::IxNetSecure::IsConnected]} {
                    if { (${argArray(-ipAddress)} != $::IxNetSecure::_initialHostname && ${argArray(-ipAddress)} != [::IxNetSecure::_tryGetAttr $::IxNetSecure::_connectionInfo hostname]) || \
                            (${argArray(-port)} != $::IxNetSecure::_initialPort && ${argArray(-port)} !=  [::IxNetSecure::_tryGetAttr $::IxNetSecure::_connectionInfo port]) } {
                        set errMsg "Cannot connect to $argArray(-ipAddress)"
                        if {$argArray(-port) != "auto"} {
                            append errMsg ":$argArray(-port)"
                        } else {
						    append errMsg ":443"
						}
                        append errMsg " as a connection is already established to [dict get $::IxNetSecure::_connectionInfo hostname]:[dict get $::IxNetSecure::_connectionInfo port]."
                        append errMsg " Please execute disconnect before trying this command again."
                        return  $errMsg
                    }
                    if { (${argArray(-sessionId)} != 0) && (${argArray(-sessionId)} != [::IxNetSecure::_tryGetAttr $::IxNetSecure::_connectionInfo sessionId]) } {
                        set errMsg "Cannot connect to session $argArray(-sessionId)"
                        append errMsg " as a connection is already established to session [dict get $::IxNetSecure::_connectionInfo sessionId]."
                        append errMsg " Please execute disconnect before trying this command again."
                        return  $errMsg
                    }
                    if { (${argArray(-serverusername)} != "") && ([::IxNetSecure::_tryGetAttr $::IxNetSecure::_connectionInfo backendType] != "ixnetwork") && \
                            (${argArray(-serverusername)} != [::IxNetSecure::_tryGetAttr $::IxNetSecure::_connectionInfo serverusername])} {
                        set errMsg "Cannot connect to a session associated with $argArray(-serverusername)"
                        append errMsg " as a connection is already established to a session associated with [dict get $::IxNetSecure::_connectionInfo serverusername]."
                        append errMsg " Please execute disconnect before trying this command again."
                        return  $errMsg
                    }
                    return $::IxNetSecure::OK
                }
                return [::IxNetSecure::Connect argArray]
        }
        "disconnect" {
            return [::IxNetSecure::Disconnect]
        }
        "readFrom" {
            # only bother with sending the file to the server if -ixNetRelative is not specified
            if {[lsearch -glob $args "-ixNetRelative"] == -1} {
                return [::IxNetSecure::_putFileOnServer [lindex $args 1]]
            } else {
                return [::IxNetSecure::_sendBuffer $ixNetCommand]
            }
        }
        "writeTo" {
            # only bother with retrieving the file from the server if -ixNetRelative is not specified
            if {[lsearch -glob $args "-ixNetRelative"] == -1} {
                return [::IxNetSecure::_createFileOnServer [lindex $args 1]]
            } else {
                return [::IxNetSecure::_sendBuffer $ixNetCommand]
            }
        }
        "getVersion" {
            if {[::IxNetSecure::IsConnected]} {
                return [::IxNetSecure::_sendBuffer $ixNetCommand]
            } else {
                return ${::IxNetSecure::_packageVersion}
            }
        }
        "setSessionParameter" {
            if {[::IxNetSecure::IsConnected]} {
                return [::IxNetSecure::_sendBuffer $ixNetCommand]
            } else {
                return [::IxNetSecure::_buffer $ixNetCommand]
            }
        }
        "setA*" -
        "setM*" {
            return [::IxNetSecure::_buffer $ixNetCommand]
        }
        default {
            return [::IxNetSecure::_sendBuffer $ixNetCommand]
        }
    }
}
