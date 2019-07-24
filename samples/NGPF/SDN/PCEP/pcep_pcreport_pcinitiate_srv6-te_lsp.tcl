#!/usr/bin/tclsh
################################################################################
#                                                                              #
#    Copyright 1997 - 2019 by IXIA  Keysight                                   #
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

################################################################################
#                                                                              #
# Description:                                                                 #
#    This script intends to demonstrate how to use NGPF PCEP API.              #
#      1. Configures a PCE on the topology1 and a PCC on topology2. SRv6 PCE   #
#         capability is enabled in PCC and PCE .The PCE has one SRv6           #
#         PCEinitiated LSP with two ERO in it. The PCC has one PreEstablished  #
#		  LSP with one ERO in it.                                              #
#      2. Stats PCC and PCE.                                                   #
#      3. Verify statistics from "Protocols Summary" view                      #
#      4. Fetch PCC SRv6 Detailed learned information                          #
#      5. Fetch PCE SRv6 Detailed learned information                          #
#      6. Send PCupdate over PreEstablished LSP(Modify ERO).                   #
#      7. Send PCupdate over PCEInitiated LSP(Modify ERO).                     #
#      8. Fetch PCE SRv6 Detailed learned information.                         #
#      9. Stop all protocols.                                                  # 
################################################################################

# Script Starts
puts "!!! Test Script Starts !!!"

# Edit this variables values to match your setup
namespace eval ::ixia {
    set ixTclServer 10.39.50.102
    set ixTclPort   5556
    set ports       {{10.39.50.96 10 17} {10.39.50.96 10 19}}
}

puts "Load ixNetwork Tcl API package"
package req IxTclNetwork

puts "Connect to IxNetwork Tcl server"
ixNet connect $::ixia::ixTclServer -port $::ixia::ixTclPort -version 8.30\
    –setAttribute strict

puts "Creating a new config"
ixNet exec newConfig

################################################################################
# 1. Protocol configuration section. Configure PCEP as per the description     #
#    give above                                                                # 
################################################################################ 
puts "Adding 2 vports"
ixNet add [ixNet getRoot] vport
ixNet add [ixNet getRoot] vport
ixNet commit

set vPorts [ixNet getList [ixNet getRoot] vport]
set vportTx [lindex $vPorts 0]
set vportRx [lindex $vPorts 1]

puts "Assigning the ports"
::ixTclNet::AssignPorts $ixia::ports {} $vPorts force

puts "Adding 2 topologies"
ixNet add [ixNet getRoot] topology -vports $vportTx
ixNet add [ixNet getRoot] topology -vports $vportRx
ixNet commit

set topologies [ixNet getList [ixNet getRoot] topology]
set topo1 [lindex $topologies 0]
set topo2 [lindex $topologies 1]

puts "Adding 2 device groups"
ixNet add $topo1 deviceGroup
ixNet add $topo2 deviceGroup
ixNet commit

set t1devices [ixNet getList $topo1 deviceGroup]
set t2devices [ixNet getList $topo2 deviceGroup]

set t1dev1 [lindex $t1devices 0]
set t2dev1 [lindex $t2devices 0]

puts "Configuring the multipliers (number of sessions)"
ixNet setAttr $t1dev1 -multiplier 1
ixNet setAttr $t2dev1 -multiplier 1
ixNet commit

puts "Adding ethernet/mac endpoints"
ixNet add $t1dev1 ethernet
ixNet add $t2dev1 ethernet
ixNet commit

set mac1 [ixNet getList $t1dev1 ethernet]
set mac2 [ixNet getList $t2dev1 ethernet]

puts "Configuring the mac addresses"
ixNet setAttr [ixNet getAttr $mac1 -mac]/singleValue\
      -value       {00:00:00:00:00:01}

ixNet setAttr [ixNet getAttr $mac2 -mac]/singleValue\
      -value       {18:03:73:C7:6C:01}
ixNet commit

puts "Add ipv4"
ixNet add $mac1 ipv4
ixNet add $mac2 ipv4
ixNet commit

set ip1 [ixNet getList $mac1 ipv4]
set ip2 [ixNet getList $mac2 ipv4]

set mvAdd1 [ixNet getAttr $ip1 -address]
set mvAdd2 [ixNet getAttr $ip2 -address]
set mvGw1  [ixNet getAttr $ip1 -gatewayIp]
set mvGw2  [ixNet getAttr $ip2 -gatewayIp]

puts "Configuring ipv4 addresses"
ixNet setAttr $mvAdd1/singleValue -value "20.20.20.2"
ixNet setAttr $mvAdd2/singleValue -value "20.20.20.1"
ixNet setAttr $mvGw1/singleValue  -value "20.20.20.1"
ixNet setAttr $mvGw2/singleValue  -value "20.20.20.2"

ixNet setAttr [ixNet getAttr $ip1 -prefix]/singleValue -value 24
ixNet setAttr [ixNet getAttr $ip2 -prefix]/singleValue -value 24

ixNet setMultiAttr [ixNet getAttr $ip1 -resolveGateway]/singleValue -value true
ixNet setMultiAttr [ixNet getAttr $ip2 -resolveGateway]/singleValue -value true
ixNet commit

puts "Adding a PCE object on the Topology 1"
set pce [ixNet add $ip1 pce]
ixNet commit
set pce [lindex [ixNet remapIds $pce] 0]

puts "Adding a PCC group on the top of PCE"
set pccGroup [ixNet add $pce pccGroup]
ixNet commit
set pccGroup [lindex [ixNet remapIds $pccGroup] 0]

# Adding PCC
puts "Adding a PCC object on the Topology 2"
set pcc [ixNet add $ip2 pcc]
ixNet commit
set pcc [lindex [ixNet remapIds $pcc] 0]

# Set pcc group multiplier to 1
ixNet setAttr $pccGroup -multiplier 1
ixNet commit

# Set PCC group's  "PCC IPv4 Address" field  to 20.20.20.1
set pccIpv4AddressMv [ixNet getAttr $pccGroup -pccIpv4Address]
ixNet setAttr $pccIpv4AddressMv/singleValue -value "20.20.20.1"
ixNet commit

# Set PCC's  "PCE IPv4 Address" field  to 20.20.20.20
set pceIpv4AddressMv [ixNet getAttr $pcc -pceIpv4Address]
ixNet setAttr $pceIpv4AddressMv/singleValue -value "20.20.20.2"
ixNet commit
################################################################################
#Set SRv6 PCE capability in PCC and PCE                                        # 
# 1. SRv6 PCE capability                                                       #
# 2. Max Segments Left                                                         #
################################################################################

# set SRv6 capability in PCC
set srv6pcccapability [ixNet getAttr $pcc -srv6PceCapability]
ixNet setAttr $srv6pcccapability/singleValue -value True
ixNet commit

#set max segment left
set srv6maxsl [ixNet getAttr $pcc -srv6MaxSL]
ixNet setAttr $srv6maxsl/singleValue -value 5
ixNet commit

# set SRv6 capability in PCE
set srv6pcecapability [ixNet getAttr $pccGroup -srv6PceCapability]
ixNet setAttr $srv6pcecapability/singleValue -value True
ixNet commit

################################################################################
# Adding Pre-Established SRv6 LSPs
# Configured parameters :
#    -initialDelegation
#    -includeBandwidth
#	 -includeLspa
#    -includeMetric
################################################################################

# Add PreEstablished LSP
ixNet setAttribute $pcc -preEstablishedSrLspsPerPcc "1"
ixNet commit

set preEstablishedSRLsps $pcc/preEstablishedSrLsps:1
set initialDelegation [ixNet getAttribute $preEstablishedSRLsps -initialDelegation]
ixNet add $initialDelegation "singleValue"
ixNet setMultiAttribute $initialDelegation/singleValue\
            -value "true"
ixNet commit

set includeBandwidth [ixNet getAttribute $preEstablishedSRLsps -includeBandwidth]
ixNet add $includeBandwidth "singleValue"
ixNet setMultiAttribute $includeBandwidth/singleValue\
            -value "true"
ixNet commit

set includeLspa [ixNet getAttribute $preEstablishedSRLsps -includeLspa]
ixNet add $includeLspa "singleValue"
ixNet setMultiAttribute $includeLspa/singleValue\
            -value "true"
ixNet commit

set includeMetricMv [ixNet getAttribute $preEstablishedSRLsps -includeMetric]
ixNet add $includeMetricMv "singleValue"
ixNet setMultiAttribute $includeMetricMv/singleValue\
            -value "true"
ixNet commit

################################################################################
# Set the properties of ERO1                                                   #
# a. Active                                                                    # 
# b. SRv6 NAI Type                                                             #
# c. F bit                                                                     #
# d. SRv6 Identifier                                                           #
# e. SRv6 Function Code                                                        #
# f. Local IPv6 Address                                                        #
# g. Remote IPv6 Address                                                       #
################################################################################
set ero1ActiveMv [ixNet getAttribute\
    $pcc/preEstablishedSrLsps/pcepEroSubObjectsList:1\
    -active]
ixNet setAttr $ero1ActiveMv/singleValue -value True

set ero1NaiTypeMv [ixNet getAttribute\
    $pcc/preEstablishedSrLsps/pcepEroSubObjectsList:1\
    -srv6NaiType]
ixNet setAttr $ero1NaiTypeMv/singleValue -value ipv6adjacency
ixNet commit

set ero1FbitMv [ixNet getAttribute\
    $pcc/preEstablishedSrLsps/pcepEroSubObjectsList:1\
    -fBit]
ixNet setAttr $ero1FbitMv/singleValue -value False

set ero1SRv6IdentifierMv [ixNet getAttribute\
    $pcc/preEstablishedSrLsps/pcepEroSubObjectsList:1\
    -srv6Identifier]
ixNet setAttr $ero1SRv6IdentifierMv/singleValue -value 2122::1

set ero1SRv6FunCodeMv [ixNet getAttribute\
    $pcc/preEstablishedSrLsps/pcepEroSubObjectsList:1\
    -srv6FunctionCode]
ixNet setAttr $ero1SRv6FunCodeMv/singleValue -value endfunction

set localIPv6AddressMv [ixNet getAttribute\
    $pcc/preEstablishedSrLsps/pcepEroSubObjectsList:1\
    -localIpv6Address]
ixNet setAttr $localIPv6AddressMv/singleValue -value 2122::2

set remoteIPv6AddressMv [ixNet getAttribute\
    $pcc/preEstablishedSrLsps/pcepEroSubObjectsList:1\
    -remoteIpv6Address]
ixNet setAttr $remoteIPv6AddressMv/singleValue -value 2122::3

ixNet commit

################################################################################
#Set  pceInitiateLSPParameters                                                 # 
#Path Setup Type -- SRv6                                                       #
################################################################################
set pathsetuptype [ixNet getAttr $pccGroup/pceInitiateLSPParameters\
    -pathSetupType]
ixNet setAttr $pathsetuptype/singleValue -value srv6
ixNet commit
################################################################################
# Set  pceInitiateLSPParameters                                                #
# 1. IP version                -- ipv6                                         #
# 2. IPv6 source endpoint      -- 2244::101                                    #
# 3. IPv6 destination endpoint -- 2344::101                                    #
################################################################################
set ipVerisionMv [ixNet getAttr $pccGroup/pceInitiateLSPParameters\
    -ipVersion]
ixNet setAttr $ipVerisionMv/singleValue -value ipv6
ixNet commit

set Ipv6SrcEndpointsMv [ixNet getAttr $pccGroup/pceInitiateLSPParameters\
    -srcEndPointIpv6] 
ixNet setAttr $Ipv6SrcEndpointsMv/singleValue -value 2244::101

set Ipv6DestEndpointsMv [ixNet getAttr $pccGroup/pceInitiateLSPParameters\
    -destEndPointIpv6]
ixNet setAttr $Ipv6DestEndpointsMv/singleValue -value 2344::101
ixNet commit

# Set  pceInitiateLSPParameters
# 1. Include srp
set Ipv4SrpEndpointsMv [ixNet getAttr $pccGroup/pceInitiateLSPParameters\
    -includeSrp]
ixNet setAttr $Ipv4SrpEndpointsMv/singleValue -value True
ixNet commit

################################################################################
# Set  pceInitiateLSPParameters                                                #
# a. Include srp                                                               #
# b. Include symbolic pathname TLV                                             #
# c. Symbolic path name   													   #
# d. Include Association                                                       #
# e. Include Bandwidth                                                         #
################################################################################
set includeLspMv [ixNet getAttr $pccGroup/pceInitiateLSPParameters\
    -includeLsp]
ixNet setAttr $includeLspMv/singleValue -value True

set includeSymbolicPathMv [ixNet getAttr $pccGroup/pceInitiateLSPParameters\
    -includeSymbolicPathNameTlv]
ixNet setAttr $includeSymbolicPathMv/singleValue True    
    
set symbolicPathNameMv [ixNet getAttr $pccGroup/pceInitiateLSPParameters\
    -symbolicPathName]
ixNet setAttr $symbolicPathNameMv/singleValue -value "IXIA_SAMPLE_LSP_1"

ixNet commit

# Add 2 EROs
ixNet setMultiAttribute $pccGroup/pceInitiateLSPParameters \
    -numberOfEroSubObjects 2                               \
    -name  {Initiated LSP Parameters}
ixNet commit
# Include Asssociation
set includeAssociationMv [ixNet getAttr $pccGroup/pceInitiateLSPParameters\
    -includeAssociation]
ixNet setAttr $includeAssociationMv/singleValue -value True

# Include bandwidth
set includebandwidthMv [ixNet getAttr $pccGroup/pceInitiateLSPParameters\
    -includeBandwidth]
ixNet setAttr $includebandwidthMv/singleValue -value True
ixNet commit
################################################################################
# Set the properties of ERO1                                                   #
# a. Active                                                                    # 
# b. SRv6 NAI Type                                                             #
# c. F bit                                                                     #
# d. SRv6 Identifier                                                           #
# e. SRv6 Function Code                                                        #
################################################################################
set ero1ActiveMv [ixNet getAttribute\
    $pccGroup/pceInitiateLSPParameters/pcepEroSubObjectsList:1\
    -active]
ixNet setAttr $ero1ActiveMv/singleValue -value True

set ero1NaiTypeMv [ixNet getAttribute\
    $pccGroup/pceInitiateLSPParameters/pcepEroSubObjectsList:1\
    -srv6NaiType]
ixNet setAttr $ero1NaiTypeMv/singleValue -value ipv6nodeid

set ero1IPv6NodeidMv [ixNet getAttribute\
    $pccGroup/pceInitiateLSPParameters/pcepEroSubObjectsList:1\
    -ipv6NodeId]
ixNet setAttr $ero1IPv6NodeidMv/singleValue -value 5556::1

set ero1FbitMv [ixNet getAttribute\
    $pccGroup/pceInitiateLSPParameters/pcepEroSubObjectsList:1\
    -fBit]
ixNet setAttr $ero1FbitMv/singleValue -value False

set ero1SRv6IdentifierMv [ixNet getAttribute\
    $pccGroup/pceInitiateLSPParameters/pcepEroSubObjectsList:1\
    -srv6Identifier]
ixNet setAttr $ero1SRv6IdentifierMv/singleValue -value 4445::1

set ero1SRv6FunCodeMv [ixNet getAttribute\
    $pccGroup/pceInitiateLSPParameters/pcepEroSubObjectsList:1\
    -srv6FunctionCode]
ixNet setAttr $ero1SRv6FunCodeMv/singleValue -value endfunction

ixNet commit

################################################################################
# Set the properties of ERO2                                                   #
# a. Active                                                                    # 
# b. SRv6 NAI Type                                                             #
# c. F bit                                                                     #
# d. SRv6 Identifier                                                           #
# e. SRv6 Function Code                                                        #
################################################################################
set ero2ActiveMv [ixNet getAttribute\
    $pccGroup/pceInitiateLSPParameters/pcepEroSubObjectsList:2\
    -active]
ixNet setAttr $ero2ActiveMv/singleValue -value True

set ero2NaiTypeMv [ixNet getAttribute\
    $pccGroup/pceInitiateLSPParameters/pcepEroSubObjectsList:2\
    -srv6NaiType]
ixNet setAttr $ero2NaiTypeMv/singleValue -value notapplicable

set ero2FbitMv [ixNet getAttribute\
    $pccGroup/pceInitiateLSPParameters/pcepEroSubObjectsList:2\
    -fBit]
ixNet setAttr $ero2FbitMv/singleValue -value False

set ero2SRv6IdentifierMv [ixNet getAttribute\
    $pccGroup/pceInitiateLSPParameters/pcepEroSubObjectsList:2\
    -srv6Identifier]
ixNet setAttr $ero2SRv6IdentifierMv/singleValue -value 4446::1

set ero2SRv6FunCodeMv [ixNet getAttribute\
    $pccGroup/pceInitiateLSPParameters/pcepEroSubObjectsList:2\
    -srv6FunctionCode]
ixNet setAttr $ero2SRv6FunCodeMv/singleValue -value enddx6function

ixNet commit     
################################################################################
# 2. Start PCC and PCE and wait for 60 seconds                                 #
################################################################################
puts "Starting all protocols"
ixNet exec startAllProtocols
after 60000

puts "Checking statistics"
################################################################################
# 3. Retrieve protocol statistics.                                             #
################################################################################
puts "Fetching all Protocol Summary Stats\n"
set viewPage {::ixNet::OBJ-/statistics/view:"Protocols Summary"/page}
set statcap [ixNet getAttr $viewPage -columnCaptions]
foreach statValList [ixNet getAttr $viewPage -rowValues] {
    foreach statVal $statValList  {
        puts "***************************************************"
        set index 0
        foreach satIndv $statVal {
            puts [format "%*s:%*s" -30 [lindex $statcap $index]\
                -10 $satIndv]
            incr index
        }
    }
}
puts "***************************************************"

################################################################################
# 4. Retrieve protocol pcc SRv6 detailed learned info                           
################################################################################
set totalNumberOfPcc 1
for {set i 1} {$i <= $totalNumberOfPcc} {incr i} {
    ixNet exec getPccSrv6LearnedInfo $pcc $i
}
puts "[string repeat * 60]"
set learnedInfoList [ixNet getList $pcc learnedInfo]
foreach learnedInfo $learnedInfoList {
    set table [ixNet getList $learnedInfo table]
    foreach t $table {
        set colList [ixNet getAttr $t -columns]
        set rowList [ixNet getAttr $t -values]
        foreach valList $rowList {
            set ndx 0  
            foreach val $valList {
                set name  [lindex $colList $ndx]
                set value $val
                set displayString [format "%-30s:\t%s" $name $value]
                puts $displayString
                incr ndx
            }
            puts "[string repeat * 60]"
        }
    }
}

################################################################################
# 5. Retrieve protocol pce SRv6 detailed learned info                          
################################################################################
set totalNumberOfPccgrp 1
for {set i 1} {$i <= $totalNumberOfPccgrp} {incr i} {
    ixNet exec getPceDetailedAllSrv6LspLearnedInfo $pccGroup $i
}
puts "[string repeat * 60]"
set pcelearnedInfoList [ixNet getList $pccGroup learnedInfo]
foreach pcelearnedInfo $pcelearnedInfoList {
    set table [ixNet getList $pcelearnedInfo table]
    foreach t $table {
        set colList [ixNet getAttr $t -columns]
        set rowList [ixNet getAttr $t -values]
        foreach valList $rowList {
            set ndx 0  
            foreach val $valList {
                set name  [lindex $colList $ndx]
                set value $val
                set displayString [format "%-30s:\t%s" $name $value]
                puts $displayString
                incr ndx
            }
            puts "[string repeat * 60]"
        }
    }
}

################################################################################
# 6. Send update over preestablished LSP                                       #
################################################################################

# Modify preestablished's ERO from pce side 
set learnedInfoUpdate [lindex [ixNet getList $pccGroup learnedInfoUpdate] 0]
set trigger1 [ixNet getList $learnedInfoUpdate pceDetailedSrv6SyncLspUpdateParams]
set ero [ixNet getA $trigger1 -configureEro]
ixNet setAttr $ero/singleValue -value "modify"
ixNet commit
set eros [ixNet getList $trigger1 pceUpdateSrv6EroSubObjectList]
set ero1 [lindex $eros 0]

set ero1SRv6IdentifierMv [ixNet getAttribute\
			$ero1 -srv6Identifier]
ixNet setAttr $ero1SRv6IdentifierMv/singleValue -value abcd::1
ixNet commit

# Send PCUpdate from Learned Info 
ixNet exec sendPcUpdate $trigger1 {2}
after 5000 
################################################################################
# 7. Send update over PCinit LSP                                               #
################################################################################
set ero1SRv6IdentifierMv [ixNet getAttribute\
    $pccGroup/pceInitiateLSPParameters/pcepEroSubObjectsList:1\
    -srv6Identifier]
ixNet setAttr $ero1SRv6IdentifierMv/singleValue -value abcd::2
ixNet commit

# Apply the changes on the fly 
ixNet exec applyOnTheFly {/globals/topology}
after 5000

################################################################################
# 8. Retrieve protocol pce SRv6 detailed learned info                          
################################################################################
set totalNumberOfPccgrp 1
for {set i 1} {$i <= $totalNumberOfPccgrp} {incr i} {
    ixNet exec getPceDetailedAllSrv6LspLearnedInfo $pccGroup $i
}
puts "[string repeat * 60]"
set pcelearnedInfoList [ixNet getList $pccGroup learnedInfo]
foreach pcelearnedInfo $pcelearnedInfoList {
    set table [ixNet getList $pcelearnedInfo table]
    foreach t $table {
        set colList [ixNet getAttr $t -columns]
        set rowList [ixNet getAttr $t -values]
        foreach valList $rowList {
            set ndx 0  
            foreach val $valList {
                set name  [lindex $colList $ndx]
                set value $val
                set displayString [format "%-30s:\t%s" $name $value]
                puts $displayString
                incr ndx
            }
            puts "[string repeat * 60]"
        }
    }
} 
################################################################################
# 9. Stop all protocols                                                        #
################################################################################
ixNet exec stopAllProtocols
puts "!!! Test Script Ends !!!"
