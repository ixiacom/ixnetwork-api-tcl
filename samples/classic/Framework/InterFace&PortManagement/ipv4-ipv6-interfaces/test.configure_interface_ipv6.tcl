################################################################################
#                                                                              #
#    Copyright © 1997 - 2018 by IXIA                                           #
#    All Rights Reserved.                                                      #
#                                                                              #
################################################################################

################################################################################
#                                                                              #
#                                LEGAL  NOTICE:                                #
#                                ==============                                #
# The following code and documentation (hereinafter "the script") is an        #
# example script for demonstration purposes only.                              #
# The script is not a standard commercial product offered by Ixia and have     #
# been developed and is being provided for use only as indicated herein. The   #
# script [and all modifications enhancements and updates thereto (whether      #
# made by Ixia and/or by the user and/or by a third party)] shall at all times #
# remain the property of Ixia.                                                 #
#                                                                              #
# Ixia does not warrant (i) that the functions contained in the script will    #
# meet the users requirements or (ii) that the script will be without          #
# omissions or error-free.                                                     #
# THE SCRIPT IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND AND IXIA         #
# DISCLAIMS ALL WARRANTIES EXPRESS IMPLIED STATUTORY OR OTHERWISE              #
# INCLUDING BUT NOT LIMITED TO ANY WARRANTY OF MERCHANTABILITY AND FITNESS FOR #
# A PARTICULAR PURPOSE OR OF NON-INFRINGEMENT.                                 #
# THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SCRIPT  IS WITH THE #
# USER.                                                                        #
# IN NO EVENT SHALL IXIA BE LIABLE FOR ANY DAMAGES RESULTING FROM OR ARISING   #
# OUT OF THE USE OF OR THE INABILITY TO USE THE SCRIPT OR ANY PART THEREOF     #
# INCLUDING BUT NOT LIMITED TO ANY LOST PROFITS LOST BUSINESS LOST OR          #
# DAMAGED DATA OR SOFTWARE OR ANY INDIRECT INCIDENTAL PUNITIVE OR              #
# CONSEQUENTIAL DAMAGES EVEN IF IXIA HAS BEEN ADVISED OF THE POSSIBILITY OF    #
# SUCH DAMAGES IN ADVANCE.                                                     #
# Ixia will not be required to provide any software maintenance or support     #
# services of any kind (e.g. any error corrections) in connection with the     #
# script or any part thereof. The user acknowledges that although Ixia may     #
# from time to time and in its sole discretion provide maintenance or support  #
# services for the script any such services are subject to the warranty and    #
# damages limitations set forth herein and will not obligate Ixia to provide   #
# any additional maintenance or support services.                              #
#                                                                              #
################################################################################
#------------------------------------------------------------------------------
# PURPOSE OF THE SCRIPT:
# This script shows how to Add an modify the properties of an IPv6 interface,
#
# Sequence of events being carried out by the script
#    1) Adds five IPv6 Interfaces on port1
#    2) Adds one IPv6 interface on port2
#    3) Modifies the properties of the IPv6 interfaces
#
# SCRIPT-GEN USED : No
# IXNCFG USED     : No
#------------------------------------------------------------------------------
source $env(IXNETWORK_SAMPLE_SCRIPT_DIR)/IxNetwork/Classic/Tcl/TestRun/config.tcl
#------------------------------------------------------------------------------
# Standard package to include all IxNetwork APIs
#------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
# PROCEDURE    : AddIp6Int
# PURPOSE      : Adding a Ipv6 connected interface.
# INPUT        : (1) object referance to the virtual port on which ipv6
#                    interface to be added
#                (2) ipv6 address
# OUTPUT       : ipv6 interface will be added in the IxNetwork GUI
# RETURN VALUE : Referance to the added interface
#-------------------------------------------------------------------------------
proc AddIp6Int {p1 ip} {
    set i1 [ixNet add $p1 interface]
    ixNet commit
    set i1 [ixNet remapIds $i1]
    puts "new interface global id: $i1"

    set ip1 [ixNet add $i1 ipv6]
    ixNet commit

    set ip1 [ixNet remapIds $ip1]
    puts "new ip6 global id: $ip1"
    ixNet setAttr $ip1 -ip $ip
    ixNet setAttr $ip1 -prefixLength 24
    ixNet commit

    ixNet setAttr $i1 -enabled true
    ixNet commit
    return $i1
}


#-------------------------------------------------------------------------------
# PROCEDURE    : ModifyIp6Int
# PURPOSE      : Modifying the properties of the IPv6 interface.
# INPUT        : (1) object referance of the interface to be modified
#                (2) object referance to the virtual port
#                (3) ipV6 Address
# OUTPUT       : Ipv6 interface will be modified as specified in theis proc
# RETURN VALUE : 0 if successful 1 if failed
#-------------------------------------------------------------------------------
proc ModifyIp6Int {i1 p1 {ipv6 2005:0:0:0:0:0:0:5}} {
    set flag 0
    set ip 2005:0:0:0:0:0:0:5
    set prefixLength 36
    set enable true

    ixNet setAttr $p1 -ip $ip
    ixNet setAttr $p1 -prefixLength $prefixLength
    ixNet setAttr $i1 -enabled $enable
    ixNet commit

    if {$enable != [ixNet getAttr $i1 -enabled]} {
        puts "** Get Attribute on enable failed"
        set flag 1
    }

    if {$ip != [ixNet getAttr $p1 -ip]} {
        puts "** Get Attribute on ip failed"
        set flag 1
    }

    if {$prefixLength != [ixNet getAttr $p1 -prefixLength]} {
        puts "Get Attribute failed on prefixLength"
        set flag 1
    }

    return $flag
}


#------------------------------------------------------------------------------
# PROCEDURE    : Action
# PURPOSE      : Encapsulating all of your testing actions
# INPUT        : (1) [list $chassis1 $card1 $port1 $client1 $tcpPort1]
#                (2) [list $chassis2 $card2 $port2 $client2 $tcpPort2]
#                (3) home; (the current directory)
# RETURN VALUE : FAILED (1) or PASSED (0)
#------------------------------------------------------------------------------
proc Action {portData1 portData2} {

    # initialize return value
    set FAILED 1
    set PASSED 0

    puts "Executing from [pwd]"
    puts "connecting to client"
    set pList [getPortList $portData1 $portData2]
    set port1 [lindex $pList 0]
    set port2 [lindex $pList 1]

    puts "Configuring for IPv6..."
    set i1 [AddIp6Int $port1 2004:0:0:0:0:0:0:1]
    set i1 [AddIp6Int $port1 2004:0:0:0:0:0:0:2]
    set i1 [AddIp6Int $port1 2004:0:0:0:0:0:0:3]
    set i1 [AddIp6Int $port1 2004:0:0:0:0:0:0:4]
    set i1 [AddIp6Int $port1 2004:0:0:0:0:0:0:5]
    set i2 [AddIp6Int $port2 2004:0:0:0:0:0:0:6]

    set ilist1 [ixNet getList $port1 interface]
    set i1     [lindex $ilist1 [expr {[llength $ilist1] - 1}]]
    set ilist2 [ixNet getList $port2 interface]
    set i2     [lindex $ilist2 [expr {[llength $ilist1] - 1}]]

    set int  $port1/interface:5
    set int6 $int/ipv6:1

    set modify [ModifyIp6Int $int $int6]

    if {$modify == 1} {
       puts "IPv6 Interface test Failed"
       return $FAILED
    } else {
       puts "IPv6 Interface test Passed"
    }

    ## Needs to remove assigned ports after test
    ixNetCleanUp
    return $PASSED
}


#-----------------------------------------------------------------------------#
# Execute the Action procedure defined above                                  #
#-----------------------------------------------------------------------------#
Execute_Action

