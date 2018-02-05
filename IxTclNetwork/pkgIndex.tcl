# Copyright © 1997 - 2017 by IXIA
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

#############################################################################################
#
# pkgIndex.tcl
#
#############################################################################################

set env(IXTCLNETWORK_8.40.1124.8) [file dirname [info script]]

package ifneeded IxTclNetwork 8.40.1124.8 {
    package provide IxTclNetwork 8.40.1124.8

    namespace eval ::ixTclNet {}
    namespace eval ::ixTclPrivate {}

    foreach fileItem1 [glob -nocomplain $env(IXTCLNETWORK_8.40.1124.8)/Generic/*.tcl] {
        if {![file isdirectory $fileItem1]} {
            source  $fileItem1
        }
    }

    source [file join $env(IXTCLNETWORK_8.40.1124.8) IxTclNetwork.tcl]
}
