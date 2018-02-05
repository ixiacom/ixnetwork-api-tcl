#############################################################################################
#
# AvailableHardwareUtils.tcl  -
#
# Copyright © 1997-2006 by IXIA.
# All Rights Reserved.
#
#
#############################################################################################

########################################################################################
# Procedure: ixTclPrivate::connectToChassis
#
# Description: Attempts to connect to all chassis given in the list
#
# Arguments:
# chassisList: 	A list of chassis names
# timeoutCount: In seconds. When to give up if could not connect to all chassis
#
# Returns: A return code of 0 for success and 1 for error.
########################################################################################

proc ::ixTclNet::ConnectToChassis {hostnameList {timeoutCount 200}} {

    set root [ixNet getRoot]
    set availableHardwareId ${root}availableHardware

    # remove any duplicate hostnames
    set tempHostnameList {}
    foreach {hostname} $hostnameList {
        if {[lsearch -all $tempHostnameList $hostname] == ""} {
            lappend tempHostnameList $hostname
        }
    }
    set hostnameList $tempHostnameList

    # add any hostname that is not the /availableHardware/chassis list
    set tempHostnameList {}
    foreach {hostname} $hostnameList {
        if {[ixNet getFilteredList $availableHardwareId chassis -hostname $hostname] == ""} {
            lappend tempHostnameList [ixNet add $availableHardwareId chassis -hostname $hostname]
        }
    }
    if {[llength $tempHostnameList] > 0} {
        ixNet commit
    }

    # get the final ids of each chassis in hostnameList
    set tempHostnameList {}
    foreach {hostname} $hostnameList {
        set chassisId [ixNet getFilteredList $availableHardwareId chassis -hostname $hostname]
        if {$chassisId != ""} {
            lappend tempHostnameList $chassisId
        }
    }
    set hostnameList $tempHostnameList

    # check the state of each chassis and if any chassis is not ready by the
    # timeoutCount throw an error
    set startTime [clock seconds]
    while {1} {
        set notReadyList {}

        foreach {chassisId} $hostnameList {
            if {[ixNet getA $chassisId -state] != "ready"} {
                lappend notReadyList $chassisId
            }
        }

        if {[llength $notReadyList] == 0} {
            return 0
        } elseif {[expr [clock seconds] - $startTime] > $timeoutCount} {
            error "Could not connect to the following hosts: $notReadyList"
        }

        after 1000
    }
}

########################################################################################
#  Procedure  :  CreatePortListWildCard
#
#  Description:  This commands creates a list of ports in a sorted order based on the
# physical slots. It accepts * as a wild card to indicate all cards or all ports on a
# card. A wild card cannot be used for chassis IP. Also, if a combination of a list
# element containing wild cards and port numbers are passed, then the port list passed
# MUST be in a sorted order, otherwise the some of those ports might not make it in the
# list. For example,
# CreatePortListWildCard {1 * *} - all cards and all ports on chassis 1
# CreatePortListWildCard {{1 1 *} {1 2 1} { 1 2 2}} - all ports on card 1 and
#                           ports 1 and 2 on card 2.
#
#  Arguments  :
#      portList         - Represented in Chassis Card Port and can be a list also
#      excludePorts     - exclude these ports from the sorted port list
#
########################################################################################
proc ::ixTclNet::CreatePortListWildCard {portList {excludePorts {}}} \
{
    set retList {}

    # If excludePorts is passed as a single list, then put braces around it
    if {[llength $excludePorts] == 3 && [llength [lindex $excludePorts 0]] == 1} {
        set excludePorts [list $excludePorts]
    }

    foreach portItem $portList {
        scan [join [split $portItem ,]] "%s %s %s" ch fromCard fromPort

        set origFromPort    $fromPort

        if { $ch == "*"} {
            puts "Error: Chassis IP cannot be a wildcard. Enter a valid number"
            return $retList
        }

        set chassisObjRef  [::ixTclNet::GetRealPortObjRef $ch]

        set maxCardsInChassis   [llength [ixNet getList  $chassisObjRef card]]
        if { $fromCard == "*"} {
            set fromCard 1
            set toCard   $maxCardsInChassis
        } else {
            set toCard   $fromCard
        }

        for {set l $fromCard} {$l <= $toCard} {incr l} {
            set cardObjRef  [::ixTclNet::GetRealPortObjRef $ch $l]
            if {$cardObjRef == ""} {
                error "No card could be found in slot $l from chassis $ch"
            }
            set maxPorts    [llength [ixNet getList  $cardObjRef port]]

            if { $origFromPort == "*"} {
                set fromPort 1
                set toPort   $maxPorts
            } else {
                set toPort   $fromPort
            }

            for {set p $fromPort} {$p <= $toPort} {incr p} {
                set portObjRef  [::ixTclNet::GetRealPortObjRef $ch $l $p]

                if {[lsearch $excludePorts "$ch $l $p"] == -1 && [lsearch $retList "$ch $l $p"] == -1} {
                    lappend retList [list $ch $l $p]
                }

            }
        }
    }

    return $retList
}

########################################################################################
# Procedure: ixTclPrivate::GetRealPortObjRef
#
# Description: Returns objRef for the specified real port
#
# Arguments: hostname1 cardNumber portNumber
#
#
# Returns: Return port objRef or null if it fails.
########################################################################################

proc ::ixTclNet::GetRealPortObjRef { hostname {cardId 0} {portId 0}} {

    set root [ixNet getRoot]
    set availHwId [lindex [ixNet -timeout 0 getList $root availableHardware] 0]
    set chassisList [ixNet -timeout 0 getList $availHwId chassis]

    set chassisRef ""

    foreach chassisItem $chassisList {
        set chassisIp [ixNet getAttr $chassisItem -hostname]
        if {$chassisIp == $hostname} {
            set chassisRef $chassisItem
            break
        }
        set chassisIp [ixNet getAttr $chassisItem -ip]
        if {$chassisIp == $hostname} {
            set chassisRef $chassisItem
            break
        }
    }
    if {$cardId == 0} {
        return $chassisRef
    }

    set cardRef ""
    if {$chassisRef != ""} {
        set cardList [ixNet -timeout 0 getList $chassisRef card]

        foreach cardItem $cardList {
            set id [ixNet getAttribute $cardItem -cardId]
            if {$id == $cardId} {
                set cardRef $cardItem
                break
            }
        }

        if {$portId == 0} {
            return $cardRef
        }

        set portRef ""
        if {$cardRef != ""} {
            set portList [ixNet -timeout 0 getList $cardRef port]

            foreach portItem $portList {
                set tempId [ixNet getAttr $portItem -portId]
                if {$tempId == $portId} {
                    set portRef $portItem
                    break
                }
            }
        }

    }
    return $portRef
}
