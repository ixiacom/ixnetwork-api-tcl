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

set env(IXTCLNETWORK_8.50.1501.9) [file dirname [info script]]

package ifneeded IxTclNetwork 8.50.1501.9 {
    package provide IxTclNetwork 8.50.1501.9
    namespace eval ::ixTclNet {}
    namespace eval ::ixTclPrivate {}
    namespace eval ::IxNet {}

    foreach fileItem1 [glob -nocomplain $env(IXTCLNETWORK_8.50.1501.9)/Generic/*.tcl] {
        if {![file isdirectory $fileItem1]} {
            source  $fileItem1
        }
    }

    if {[info command bgerror]==""} {
        # Avoid TK popups from background errors.
        proc bgerror {args} {
            puts "$args"
        }
    }

    source [file join $env(IXTCLNETWORK_8.50.1501.9) IxTclNetwork.tcl]
  
}

