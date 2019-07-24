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

########################################################################################
# Procedure: ::ixTclNet::ShowAttributeValues
#
# Description:  Gets the value of attributes for an objectRef and print them.
#
# Arguments: objRef     - object ref.
#
#
########################################################################################
proc ::ixTclNet::ShowAttributeValues {objRef} {
    set totaloptionList [ixNet help -attList $objRef]
    foreach {option isReadOnly type} [join $totaloptionList] {
        logMsg "ixNet getAttribute $option:[ixNet getAttribute $objRef $option]"
    }
}

###############################################################################
# Procedure: ixTclPrivate::message
#
# Description: This command is used to write messages to the log.
#              Usage is as follows:
#                  log message "This is my message"
#
###############################################################################
proc ::ixTclPrivate::message {args} {
    set ioHandle stdout
    set argLen [llength $args]
    set type   logger

    if {[lindex $args 0] == "-nonewline"} {
        set args [lreplace $args 0 0]

        catch {puts -nonewline $ioHandle [join $args " "]}

    } else {
        catch {puts $ioHandle [join $args " "]}
    }

    flush $ioHandle

    # required not only for flushing the stdout, but also to flush anything from the
    # open socket connections  (should probably revisit the socket code later)
    update
}

########################################################################
# Procedure: ::ixTclNet::logMsg
#
# Description: This command wraps the logger command logger message
#
# Arguments: args - a list of valid arguments
#
# Results: Returns 0 for ok and 1 for error.  WARNING: Cannot use TCL_OK
#          and TCL_ERROR at this point.  It was failing on certain unix
#          and linux combinations
########################################################################
proc ::ixTclNet::logMsg {args} {
    set retCode 0
    if {[lindex $args 0] == "-nonewline"} {
        set args [lreplace $args 0 0]
        if {[catch {eval ::ixTclPrivate::message -nonewline $args} err]} {
            set retCode 1
        }
    } else {
        if {[catch {eval ::ixTclPrivate::message $args} err]} {
            set retCode 1
        }
    }
    return $retCode
}
