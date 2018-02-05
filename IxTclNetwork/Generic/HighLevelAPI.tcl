#############################################################################################
#
# HighLevelAPI.tcl  -
#
# Copyright © 1997-2009 by IXIA.
# All Rights Reserved.
#
#
#############################################################################################

##########################################################################################################################
#     Procedure Name: ixTclNet::GetProtocolHeaderFromPacket
#     Description:
#		This API operates on both
#		/traffic/trafficItem/configElement/stack and
#		/vport/capture/currentPacket/stack lists and returns objref to
#		Nth occurence of protocol header with matching name
#
#     Input:
#          stackOwner:
#		/traffic/trafficItem/configElement or
#		/vport/capture/currentPacket
#	   name: text which will be matched against displayName attribute of
#		items on a list
#	   index: 1 based index of occurence to return
#    Return:
#            objref when matching protocol header was found
#            empty otherwise
##########################################################################################################################
proc ::ixTclNet::GetProtocolHeaderFromPacket {stackOwner name index} {
    if {$index < 1} {
	return
    }
    set headers [ixNet getList $stackOwner stack]
    foreach header $headers {
	set headerName [ixNet getAttr $header -displayName]
	if {[string compare $name $headerName] == 0} {
	    set index [expr {$index - 1}]
	    if {$index == 0} {
		return $header
	    }
	}
    }
    return
}

##########################################################################################################################
#     Procedure Name: ixTclNet::GetFieldFromProtocolHeader
#     Description:
#		This API operates on both
#		/traffic/trafficItem/configElement/stack/fields and
#		/vport/capture/currentPacket/stack/fields lists and returns objref to
#		Nth occurence of field with matching name
#
#     Input:
#          protocolHeader:
#		/traffic/trafficItem/configElement/stack:<instance> or
#		/vport/capture/currentPacket:<instance>
#	   name: text which will be matched against displayName attribute of
#		items on a list
#	   index: 1 based index of occurence to return
#    Return:
#            objref when matching field was found
#            empty otherwise
##########################################################################################################################
proc ::ixTclNet::GetFieldFromProtocolHeader {protocolHeader name index} {
    if {$index < 1} {
	return
    }
    set fields [ixNet getList $protocolHeader field]
    foreach field $fields {
	set fieldName [ixNet getAttr $field -displayName]
	if {[string compare $name $fieldName] == 0} {
	    set index [expr {$index - 1}]
	    if {$index == 0} {
		return $field
	    }
	}
    }
    return
}

##########################################################################################################################
#    Procedure Name: ixTclNet::TakeSystemCSVSnapshot
#    Description:
#           This API takes system wide CSV snapshot according to the specified snapshotSettings
#    Input:
#           scheduleTime – time lapse in seconds when to take snapshot from current time. Default value: 0 – take snapshot immediately.
#           snapshotSettings – a list of key/value (separated by semi-column) specifying the setting. For example, one can set snapshotSettings as
#                   set snapshotSettings [list "csv_location:myfile" "db_location:C:\\temp" "name:test123"]
#           The available setting options can be retrieved through a helper procedure. ixNet:: GetDefaultSnapshotSettings
#    Return:
#            0 – success
#            1 - failed with optional error message
##########################################################################################################################
#proc ::ixTclNet::TakeSystemCSVSnapshot { snapshotSettings {scheduleTime  "0"} } {
#          set status ""
#          catch { set status [ixNet exec TakeSystemCSVSnapshot $snapshotSettings  $scheduleTime] } err
#          if { $status == "::ixNet::OK" } {
#               return 0
#          } else {
#               if { $err !="" } {
#                    error "$err"
#               }
#               return 1
#          }
#}

##########################################################################################################################
#     Procedure Name: ixTclNet::TakeCategoryCSVSnapshot
#     Description:
#          This API takes CSV snapshot for the specified category according to the specific snapshotSettings.
#     Input:
#          Category – A list to specify what categories a user wants to take snapshot. For example, for one asks to take
#                          snapshot for all BGP related stats. The supported categories can be retrieved through a helper procedure
#                          ixTclNet::GetAvailableCSVSnapshotCategories.
#          snapshotSettings – a list of key/value specifying the setting. The available setting options can be retrieved
#                          through a helper procedure. ixNet:: GetDefaultSnapshotSettings
#    Return:
#            0 – success
#            1 - failed, with optional error message
##########################################################################################################################
#proc ::ixTclNet::TakeCategoryCSVSnapshot { category snapshotSettings } {
#          set status ""
#          catch { set status [ixNet exec TakeCategoryCSVSnapshot $category $snapshotSettings ] } err
#          if { $status == "::ixNet::OK" } {
#               return 0
#          } else {
#               if { $err !="" } {
#                    error "$err"
#               }
#               return 1
#         }
#}

##########################################################################################################################
#     Procedure Name: ixTclNet::TakeViewCSVSnapshot
#     Description:
#           This API takes CSV snapshot for a list of views specified according to the specific snapshotSettings.
#     Input:
#           viewList – A list to specify what views a user wants to take snapshot. For example, for one asks to take
#                          snapshot for “Port Statistics” “BGP Aggregated” etc.
#           snapshotSettings – a list of key/value specifying the setting. The available setting options can be retrieved
#                                        through a helper procedure. ixNet:: GetDefaultSnapshotSettings
#    Return:
#            0 – success
#            1 - failed, with optional error message
##########################################################################################################################
proc ::ixTclNet::TakeViewCSVSnapshot { viewList snapshotSettings } {
    set status ""
    catch { set status [ixNet exec TakeViewCSVSnapshot $viewList $snapshotSettings ] } err
    if { $status == "::ixNet::OK" } {
	return 0
    } else {
	if { $err !="" } {
	    error "$err"
	}
	return 1
    }
}

##########################################################################################################################
#     Procedure Name: ixTclNet::GetAvailableCSVSnapshotCategories
#     Description:
#           This API retrieves the available categories supported by IxNetwork.
#     Return:
#            A list of category names
##########################################################################################################################
#proc ::ixTclNet::GetAvailableCSVSnapshotCategories {  }  {
#          set status ""
#          catch {set status [ixNet exec GetAvailableCSVSnapshotCategories ] } err
#          if { $status != "" }  {
#               set categoryList [ ixTclNet::ParseExecArray $status ]
#               return $categoryList
#          }  else {
#               return $err
#          }
#}

##########################################################################################################################
#    Procedure name: SetSnapshotSettingsToDefault
#    Description:
#        Set the snapshot setting to system default for a specific settings
#    Input:
#        snapshotSettingName – the name of the snapshot settings
#    Return:
#            0 – success
#            1 - failed, with optional error message
##########################################################################################################################
proc ::ixTclNet::SetSnapshotSettingsToDefault { snapshotSettingName } {
    set status ""
    catch { set status [ixNet exec SetSnapshotSettingsToDefault $snapshotSettingName ] } err
    if { $status == "::ixNet::OK" } {
	return 0
    } else {
	if { $status !="" } {
	    error "$err"
	}
	return 1
    }
}

##########################################################################################################################
#     Procedure name: GetDefaultSnapshotSettings
#     Description:
#	Get the default system settings for snapshot operation. Note that the name of the default snapshot settings is predefined as "DefaultSnapshotSettings"
#     Return:
#           A list of key/value specifying the default system settings.
##########################################################################################################################
proc ::ixTclNet::GetDefaultSnapshotSettings { }  {
    set status ""
    catch {set status [ixNet exec GetDefaultSnapshotSettings ] } err
    if { $status != "" }  {
	set settingList [ ixTclNet::ParseExecArray $status ]
	return $settingList
    }  else {
	return $err
    }
}

##########################################################################################################################
#     Procedure name: GetDefaultSnapshotSettings
#     Description:
#          This procedure retrieves the snapshot data status for the specified request name.
#     Input:
#          requestName – This is the unique name in the snapshotSettings List passed into the three high-level
#                                 APIs – TakeSystemCSVSnapshot, TakeCategoryCSVSnapshot, and TakeViewCSVSnapshot.
#     Return:
#          0 – complete, successful
#          1 - complete, failed
#          2 – in progress
##########################################################################################################################
proc ::ixTclNet::GetCSVSnapshotStatus { requestName } {
    error "This function is not available yet, pending SV anchor"
}

###################################################################################################
# Procedure: ::ixTclNet::GetFilteredSnapshotDataByPageRange
#
# Description: Get stats value through snapshot API for a list of columns in a range of pages
#
# Input arguments
#            viewCaption - Name of the view to retrieve statistics, such as "Port Statistics",
#                          "Traffic Statistics"
#            needCols    - List of column names read from IxNetwork GUI view
#            timeout     - timeout in seconds to get the stats
#            fromPageNumber - Number of the starting page from that to query data
#            fromPageNumber - Number of the last page from that to query data
#            csvFilePath    - The path of the csv file to which the queried data is stored through appending
#                             the data to the end of the file. The default value is "", meaning no data
#                             is output to a file
#            dumpDataOnly - Indicator whether to dump data to a file only or not. Default value is false.
#                           If this flag is set to true, the output array o_StatValueArray will be
#                           empty and thus no memory is needed to store data in o_StatValueArray.
#
# Output arguments
#            o_StatValueArray - An array of stat values for the specified stats.
#                               Note that an array in Tcl is similar to a Hash table in Java
#                               and C#.
#                               The key of the array is "<sequence number>|<row label>", where sequence
#                               number is the order number of a row in this query.
# Return:
#      Total number of rows retrieved.
####################################################################################################
proc ::ixTclNet::GetFilteredSnapshotDataByPageRange { viewCaption needCols fromPageNumber toPageNumber \
		o_StatValueArray timeout {csvFilePath ""} {dumpDataOnly "false"} } {

    upvar $o_StatValueArray statValueArray
    if {[info exists statValueArray]} {
	unset statValueArray
    }

    if { $fromPageNumber < 1 } {
	error "::ixTclNet::GetFilteredSnapshotDataByPageRange: From page number should be greater than 0"
    }
    if { $fromPageNumber  > $toPageNumber } {
	error "::ixTclNet::GetFilteredSnapshotDataByPageRange: From page number is greater than to page number"
    }
    if { $dumpDataOnly == "true" && $csvFilePath == "" } {
	error "::ixTclNet::GetFilteredSnapshotDataByPageRange: CSV file is not specified for dump data only option"
    }
    set statViewObjRef [::ixTclNet::GetViewObjRef $viewCaption ]

    set pageNumber 1
    set totalPages [ixNet getAttribute $statViewObjRef -totalPages]
    #puts "totalPages = $totalPages"
    set allowPaging  true
    if { $totalPages == 0 } {
	set allowPaging  false
	set totalPages 1
    }

    if { $toPageNumber > $totalPages } {
	puts "toPageNumber is greater than total pages, reset toPageNumber to: $totalPages"
	set toPageNumber $totalPages
    }

    set fd ""
    if { $csvFilePath != "" } {
	set fd [open $csvFilePath "a+"]
    }
    set rowNum 0
    for { set pageNumber $fromPageNumber } { $pageNumber <= $toPageNumber } { incr pageNumber } {
	# switch page
	if { $allowPaging } {
	    ixNet setAttribute $statViewObjRef -currentPageNumber $pageNumber
	    ixNet commit
	}

	set timeout2 [expr $timeout *1000 ]
	set dataReady true
	while {[ixNet getAttribute $statViewObjRef -isReady] == "false" } {
	    if { $timeout2 < 0 } {
		set dataReady  false
		break
	    }
	    after 500
	    incr timeout2 -500
	}
	if { $dataReady == false } {
	    puts "Data is not available for page $pageNumber in $timeout seconds. This page is skipped"
	    incr pageNumber
	    continue
	}

	# Get snapshot data for the statistics page
	set snapshot [ixNet getAttribute $statViewObjRef -snapshotData]

	# Get lists of row names, column names, and cell values
	set rowNames [lindex $snapshot 1]
	set colNames [lindex $snapshot 2]
	set allVals [lindex $snapshot 3]
	set colNames_current ""
	if { [llength $snapshot] } {
	    set colNames_current [lindex $snapshot 4]
	}
	#puts "snapshot= $snapshot"

	# Get the column index
	set colIndexes {}
	foreach neededCol $needCols {
	    set colIndex -1
	    set curIndex 0
	    foreach colName $colNames {
		#puts "colName = $colName"
		if {[string tolower $colName] == [string tolower $neededCol]
		    || [string tolower [lindex $colNames_current $curIndex] ] == [string tolower $neededCol] } {
		    set colIndex $curIndex
		    break
		}
		incr curIndex
	    }
	    lappend colIndexes $colIndex
	}

	set rowCount [llength $rowNames]

	# Get data for the specified columns and store them into an array (Hash table)
	for {set rowIndex 0} {$rowIndex < $rowCount} {incr rowIndex} {
	    set rowName [lindex $rowNames $rowIndex]
	    set rowVals [lindex $allVals $rowIndex]
	    set needVals {}
	    foreach colIndex $colIndexes {
		if {$colIndex != -1} {
		    set cellVal [lindex $rowVals $colIndex]
		} else {
		    set cellVal "(missing column)"
		}
		lappend needVals $cellVal
	    }
	    if { $csvFilePath != "" } {
		puts -nonewline $fd "[format "%06d" $rowNum]|$rowName"
		foreach val1 $needVals {
		    puts -nonewline $fd ",$val1"
		}
		puts $fd ""
	    }
	    if { $dumpDataOnly == "false" } {
		set statValueArray([format "%06d" $rowNum]|$rowName) $needVals
	    }
	    incr rowNum
	}
    }
    if { $fd != "" } {
	close $fd
    }
    return $rowNum
}

##############################################################################################
# Procedure: ::ixTclNet::GetViewObjRef
#
# Description: Get object reference for a view
#
# Input arguments
#            viewCaption - Name of the view to retrieve statistics, such as "Port Statistics",
#                          "Traffic Statistics"
# Output arguments
#            N/A
# Return
#           The object reference corresponding to the input view caption
##############################################################################################
proc ::ixTclNet::GetViewObjRef { viewCaption } {
    set viewsToCheck {
        statistics statViewBrowser
        statistics trafficStatViewBrowser
        statistics/drilldown/flowDetective view
        statistics/drilldown/egressByFlow view
        statistics/drilldown/egressByPort view
    }
    set statViewObjRef ""
    foreach {parentRef statBrowser} $viewsToCheck {
	set statViewList [ixNet getList [ixNet getRoot]$parentRef $statBrowser]
	foreach statView $statViewList {

	    if {[string tolower [ixNet getAttribute $statView -name]] == [string tolower $viewCaption ] } {
		if {[ixNet getAttribute $statView -enabled] == "false"} {
		    ixNet setAttribute $statView -enabled true
		    ixNet commit
		}
		set statViewObjRef $statView
		break
	    }
	}
	if {$statViewObjRef != ""} {
	    break
	}
    }

    if {$statViewObjRef == ""} {
	error "Failed to find object ref for View: $viewCaption"
    }
    return $statViewObjRef
}

########################################################################################
# Procedure: ::ixTclNet::SaveConfigFile
#
# Description: Save current IxNetwork configuration into a file
#
# Input arguments
#       outputFileName - Name of the configuration file
# Output arguments
#       N/A
#
########################################################################################
proc ::ixTclNet::SaveConfigFile {outputFileName} {
    if { $outputFileName == "" } {
	error "::ixTclNet::SaveConfigFile - configuration file name is not specified"
    }
    ixNet exec saveConfig [ixNet writeTo $outputFileName -ixNetRelative -overwrite]
}

#####################################################################################
# Procedure: GetPGIDListbyFlowPortLabel
# Description: Get a list of PGIDs for the specified flow label and port label
# Input arguments:
#       portlabel - Label of the receiver port, such as 10.200.114.34:03:01-Ethernet
#       flowlabel - Label of the flow(s), such as SourceAddress-10.10.2.1
# Return:
#       a list of PGIDs
#####################################################################################
proc ::ixTclNet::GetPGIDListbyFlowPortLabel { rxportlabel flowlabel } {
    puts "deprecated proc"
    set root [ixNet getRoot]
    set execArray [ ixNet exec getPGIDList $root/statistics $rxportlabel $flowlabel ]
    #puts "execArray= $execArray"
    if { ! [regexp "::ixNet::OK" $execArray ] } {
	error "Cannot find PGIDs for the specified port and flow labels"
    }
    set pgidList [ ::ixTclNet::ParseExecArray $execArray ]
    return $pgidList
}

#########################################################################
# Procedure: ParseExecArray
# Description: Parse an array returned by an ixNet exec function,
#              such as ::ixNet::OK-{kArray,{{kInteger,0},{kInteger,2}}}
# Input arguments: a
#      i_array  - string returned by an ixNet exec function
# Return:
#      a list of values embedded in the input string.
#########################################################################
proc ::ixTclNet::ParseExecArray { i_array } {
    set tmp1 [expr {[string first "-" $i_array ] + 1 } ]
    set tmp2 [string range $i_array $tmp1 end ]
    set tmp2 [lindex $tmp2 0]
    # get list of lists
    set tmp3 [string trimleft $tmp2 "kArray,"]
    set tmp3 [lindex $tmp3 0]

    set myLists [split $tmp3 ",\}"]
    set count [llength $myLists]
    set myValues ""
    for {set i 1} { $i < $count } { incr i 3 } {
	lappend myValues [lindex $myLists $i]
    }
    return $myValues
}

##########################################################################################################
# Procedure: GetStatsFooters
# Description: Get footers for a specified stats view
# Input arguments:
#      viewCaption - The caption of the stats view, such as "Traffic Statistics"
#      cols        - A list of column names for which the footers will be retrieved
#      types       - A list of footer types which maps to the column names. The footer type
#                    for a column can be one of types:"avg" -- average of the column stat,
#                                                     "sum" -- Sum of column stat
#                                                     "max" -- Maximum of the column stat
#                                                     "min" -- Minimum of the column stat
#                                                     "count" -- Total count of the rows
#      pageNumber - The page on which the footers are to be retrieved. Default value is "currentPage".
#                   For not pagable stats, the page number is ignored.
# Return:
#      A list of footer values corresponding to the specified columns.
# Exception:
#      (1) If a column name cannot be found in the stats view
#      (2) If a footer type does apply to the specified column
##########################################################################################################
proc ::ixTclNet::GetStatsFooters { viewCaption cols types {pageNumber "currentPage"}} {
    puts "deprecated proc"
    set viewsToCheck {
        statistics statViewBrowser
        statistics trafficStatViewBrowser
        statistics/drilldown/flowDetective view
        statistics/drilldown/egressByFlow view
        statistics/drilldown/egressByPort view
    }
    set statViewObjRef ""
    foreach {parentRef statBrowser} $viewsToCheck {
	set statViewList [ixNet getList [ixNet getRoot]$parentRef $statBrowser]
	foreach statView $statViewList {

	    if {[string tolower [ixNet getAttribute $statView -name]] == [string tolower $viewCaption ] } {
		if {[ixNet getAttribute $statView -enabled] == "false"} {
		    ixNet setAttribute $statView -enabled true
		    ixNet commit
		}
		set statViewObjRef $statView
		break
	    }
	}
	if {$statViewObjRef != ""} {
	    break
	}
    }

    if {$statViewObjRef == ""} {
	error "Failed to find view: $viewCaption"
	return 1
    }
    #puts "Browser is enabled for the stats: $viewCaption"

    if { $pageNumber != "currentPage" } {
	set totalPages [ixNet getAttribute $statViewObjRef -totalPages]
	if { $totalPages != 0 } {
	    ixNet setAttribute $statViewObjRef -currentPageNumber $pageNumber
	    ixNet commit
	}
    }

    set timeout2 60000
    set dataReady true
    while {[ixNet getAttribute $statViewObjRef -isReady] == "false" } {
	if { $timeout2 < 0 } {
	    set dataReady  false
	    break
	}
	after 500
	incr timeout2 -500
    }
    if { $dataReady == false } {
	error "Data is not available in 60 seconds. Exiting the call."
	return 1
    }

    set cols2 [lappend cols "Dummy columns"]
    set vals [ixNet exec getStatsFooters  [ixNet getRoot]/statistics $viewCaption $cols2 $types]
    #puts "vals= $vals"
    if { [regexp -nocase -- "::IxNet::OK-{kString,(.*)}" $vals -> var] == 1 } {
	set valList [split $var ","]
	return $valList
    }
    # error
    error "Exception: $vals"
}

##########################################################################################################
# Procedure: GetRowLabelFromIndex
# Description: Get the row label from input row index
# Input arguments:
#      rowIndex - row index
# Return:
#      Row label corresponding to the input row index
###########################################################################################################
proc ::ixTclNet::GetRowLabelFromIndex { rowIndex } {
    puts "deprecated proc"
    set root [ixNet getRoot]
    if { [ixNet getAtt $root/statistics/trafficStatViewBrowser:"Traffic\ Statistics" -enabled ] == false } {
	ixNet setAtt $root/statistics/trafficStatViewBrowser:"Traffic\ Statistics" -enabled True
    }
    ixNet commit

    set pageSize [ ixNet getAtt $root/statistics/trafficStatViewBrowser:"Traffic\ Statistics" -pageSize ]
    set pageNumber [ expr { $rowIndex / $pageSize + 1 } ]
    ixNet setAtt $root/statistics/trafficStatViewBrowser:"Traffic\ Statistics" -currentPageNumber $pageNumber
    ixNet commit

    if {[::ixTclNet::isStatsReady $root/statistics/trafficStatViewBrowser:"Traffic\ Statistics" 10] == false} {
	error "Traffic Statistics view is not ready"
    }

    # Get row label
    set rowLabel [ ixNet getAtt $root/statistics/trafficStatViewBrowser:"Traffic\ Statistics"/row:$rowIndex -name ]
    return $rowLabel
}

############################################################################################
# Procedure: CreateEgressTrackingByPortView
# Description: Create egress tracking by port view according to port label
# Input arguments:
#    rxPort - The label of receiver port, such as 10.200.117.34:03:02-Ethernet
# Return:
#    caption of the created view
############################################################################################
proc ::ixTclNet::CreateEgressTrackingByPortView { rxPort } {
    set root [ixNet getRoot]
    set dwView [ixNet add [ixNet getRoot]/statistics/drilldown egressByPort]

    ixNet setAttribute $dwView -rxPort $rxPort
    ixNet commit
    set dwView [ixNet remapIds $dwView]
    set statObjRef [ixNet getList $dwView "view"]
    set splitStringList [split [lindex $statObjRef 0] "\""]
    set viewCaption [lindex $splitStringList 1]
    return $viewCaption
}

######################################################################################################
# Procedure: CreateEgressTrackingByPortViewUseRowLabel
# Description: Create egress tracking by port view according to row label
# Input arguments:
#       rowLabel  - Row label from which the port label is retrieved for egress tracking by port
# Return:
#       Caption of the Egress tracking by port view
######################################################################################################

proc ::ixTclNet::CreateEgressTrackingByPortViewUseRowLabel { rowLabel } {
    puts "deprecated proc"
    set root [ixNet getRoot]
    # Configure the drilldown view

    set dwView [ixNet add [ixNet getRoot]/statistics/drilldown egressByPort]
    ixNet setAttribute $dwView -rowLabel $rowLabel
    ixNet commit
    set dwView [ixNet remapIds $dwView]
    set statObjRef [ixNet getList $dwView "view"]

    set splitStringList [split [lindex $statObjRef 0] "\""]
    set viewCaption [lindex $splitStringList 1]
    return $viewCaption
}

######################################################################################################
# Procedure: CreateEgressTrackingByFlowView
# Description: Create egress tracking by flow view according to port label and PGID
# Input arguments:
#       rxPort - Label of the receiver port, such as 10.200.117.34:03:02-Ethernet
#       pgid   - packet group identifier
# Return:
#       Caption of the Egress tracking by flow view
######################################################################################################

proc ::ixTclNet::CreateEgressTrackingByFlowView { rxPort pgid } {
    puts "deprecated proc"
    set root [ixNet getRoot]

    # Configure the drilldown view
    set dwView [ixNet add [ixNet getRoot]/statistics/drilldown egressByFlow]
    ixNet setAttribute $dwView -pgid $pgid
    ixNet setAttribute $dwView -rxPort $rxPort
    ixNet commit
    set dwView [ixNet remapIds $dwView]
    set statObjRef [ixNet getList $dwView "view"]

    set splitStringList [split [lindex $statObjRef 0] "\""]
    set viewCaption [lindex $splitStringList 1]
    return $viewCaption
}

######################################################################################################
# Procedure: CreateEgressTrackingByFlowViewUseRowLabel
# Description: Create egress tracking by flow view according to row label
# Input arguments:
#       rowLabel - Row label for which egress tracking by flow is enabled
# Return:
#       Caption of the Egress tracking by flow view
######################################################################################################

proc ::ixTclNet::CreateEgressTrackingByFlowViewUseRowLabel { rowLabel } {
    puts "deprecated proc"
    set root [ixNet getRoot]
    # Configure the drilldown view

    set dwView [ixNet add [ixNet getRoot]/statistics/drilldown egressByFlow]
    ixNet setAttribute $dwView -rowLabel $rowLabel
    ixNet commit
    set dwView [ixNet remapIds $dwView]
    set statObjRef [ixNet getList $dwView "view"]

    set splitStringList [split [lindex $statObjRef 0] "\""]
    set viewCaption [lindex $splitStringList 1]
    return $viewCaption
}

#######################################################################################################
#
# Procedure: CreateDeadFlowView
#
# Description: Create deadflow view
#
# Input arguments:
#     maxResults - Maximum number of rows configured for the dead flow
#     deadFlowTimout - Timeout for the dead flow (in seconds)
#     sortType - Specify how to sort the dead flow rows displayed in the view: descending or ascending. Default value is ascending.
# Return:
#     caption of the dead flow view
#
########################################################################################################
proc ::ixTclNet::CreateDeadFlowView { maxResults deadFlowTimeout {sortType "ascending"}} {
    puts "deprecated proc"

    set root [ixNet getRoot]
    catch {ixNet exec clearView $root/statistics/drilldown/flowDetective } err
    set fdView [ixNet add [ixNet getRoot]/statistics/drilldown flowDetective]

    ixNet setAttribute $fdView -type deadflow
    ixNet setAttribute $fdView -maxResults $maxResults

    ixNet setAttribute $fdView -deadFlowTimeout $deadFlowTimeout

    ixNet setAttribute $fdView/deadFlow -sortType $sortType
    ixNet commit
    set fdView [ixNet remapIds $fdView]

    set statObjRef [ixNet getList $fdView "view"]
    set splitStringList [split [lindex $statObjRef 0] "\""]
    set viewCaption [lindex $splitStringList 1]
    return $viewCaption
}

##################################################################################################################################
# Procedure: CreateConditionalFlowDetectiveView
#
# Description: Create flow detective view with conditional stats
#
# Input arguments:
#     maxResults - The maximum number of rows allowed for the conditional stats view
#     performerType - Type of the performer to show: showBestPerformers or showWorstPerformers
#     sortStatName - Name of stat for sorting
#     deadFlowTimeout - Timeout for the dead flow (in seconds)
#     isDeadflowIncluded - Indicate whether the conditional stats view includes (True) the dead flow rows or not (False). Deafult value is True.
# Return:
#     Caption of the flow detective view
##################################################################################################################################
proc ::ixTclNet::CreateConditionalFlowDetectiveView { maxResults performerType sortStatName deadFlowTimeout {isDeadflowIncluded True} }  {
    puts "deprecated proc"
    set root [ixNet getRoot]
    catch {ixNet exec clearView $root/statistics/drilldown/flowDetective } err

    set fdView [ixNet add [ixNet getRoot]/statistics/drilldown flowDetective]

    ixNet setAttribute $fdView -type conditional
    ixNet setAttribute $fdView -maxResults $maxResults

    ixNet setAttribute $fdView -deadFlowTimeout $deadFlowTimeout

    ixNet setAttribute $fdView/conditional -sortType $performerType
    ixNet setAttribute $fdView/conditional -sortStatName $sortStatName
    ixNet setAttribute $fdView/conditional -includeDeadFlows $isDeadflowIncluded
    ixNet commit
    set fdView [ixNet remapIds $fdView]
    set statObjRef [ixNet getList $fdView "view"]
    set splitStringList [split [lindex $statObjRef 0] "\""]
    set viewCaption [lindex $splitStringList 1]
    return $viewCaption
}

########################################################################################
# Procedure: ::ixTclNet::GetFilteredSnapshotData
#
# Description: Get stats value through snapshot API for a list of columns.
#              This method is obsolete. User should use GetFilteredSnapshotDataByPageRange
#
# Input arguments
#            viewCaption - Name of the view to retrieve statistics, such as "Port Statistics",
#                          "Traffic Statistics"
#            needCols    - List of column names read from IxNetwork GUI view
#            timeout     - timeout in seconds to get the stats
#            pageNumber  - The number of the specified page to retrieve data. Default is "currentPage":
#                          the current page.
# Output arguments
#            o_StatValueArray - An array of stat values for the specified stats.
#                               Note that an array in Tcl is similar to a Hash table in Java
#                               and C#.
#                               The key of the array is "<row sequence number>|<row label>"
#                               where row sequence number is the relative sequence number of rows
#                               in the retrieved data
# Return:
#      Total number of rows retrieved.
########################################################################################
proc ::ixTclNet::GetFilteredSnapshotData {viewCaption needCols o_StatValueArray timeout {pageNumber "currentPage"}} {
    puts "deprecated proc"
    upvar $o_StatValueArray statValueArray
    if {[info exists statValueArray]} {
	unset statValueArray
    }

    # puts "needCols = $needCols"
    set viewsToCheck {
        statistics statViewBrowser
        statistics trafficStatViewBrowser
        statistics/drilldown/flowDetective view
        statistics/drilldown/egressByFlow view
        statistics/drilldown/egressByPort view
    }
    set statViewObjRef ""
    foreach {parentRef statBrowser} $viewsToCheck {
	set statViewList [ixNet getList [ixNet getRoot]$parentRef $statBrowser]
	foreach statView $statViewList {

	    if {[string tolower [ixNet getAttribute $statView -name]] == [string tolower $viewCaption ] } {
		if {[ixNet getAttribute $statView -enabled] == "false"} {
		    ixNet setAttribute $statView -enabled true
		    ixNet commit
		}
		set statViewObjRef $statView
		break
	    }
	}
	if {$statViewObjRef != ""} {
	    break
	}
    }

    if {$statViewObjRef == ""} {
	puts "Error in getting stat View $viewCaption"
	return 1
    }
    #puts "Browser is enabled for the stats: $viewCaption"

    set totalPages [ixNet getAttribute $statViewObjRef -totalPages]
    set allowPaging  true
    if { $totalPages == 0 } {
	set allowPaging  false
	set totalPages 1
    }

    if { $pageNumber !="currentPage"  &&  $allowPaging } {
	# switch page
	ixNet setAttribute $statViewObjRef -currentPageNumber $pageNumber
	ixNet commit
    }

    set timeout2 [expr $timeout *1000 ]
    set dataReady true
    while {[ixNet getAttribute $statViewObjRef -isReady] == "false" } {
	if { $timeout2 < 0 } {
	    set dataReady  false
	    break
	}
	after 500
	incr timeout2 -500
    }
    if { $dataReady == false } {
	error "Data is not available for page $pageNumber in $timeout seconds."
    }

    # Get snapshot data for the statistics page
    set snapshot [ixNet getAttribute $statViewObjRef -snapshotData]

    # Get lists of row names, column names, and cell values
    set rowNames [lindex $snapshot 1]
    set colNames [lindex $snapshot 2]
    set allVals [lindex $snapshot 3]
    set colNames_current ""
    if { [llength $snapshot] } {
	set colNames_current [lindex $snapshot 4]
    }
    #puts "snapshot= $snapshot"

    # Get the column index
    set colIndexes {}
    foreach neededCol $needCols {
	set colIndex -1
	set curIndex 0
	foreach colName $colNames {
	    #puts "colName = $colName"
	    if {[string tolower $colName] == [string tolower $neededCol]
		|| [string tolower [lindex $colNames_current $curIndex] ] == [string tolower $neededCol] } {
		set colIndex $curIndex
		break
	    }
	    incr curIndex
	}
	lappend colIndexes $colIndex
    }

    set rowNum 0
    set rowCount [llength $rowNames]

    # Get data for the specified columns and store them into an array (Hash table)
    for {set rowIndex 0} {$rowIndex < $rowCount} {incr rowIndex} {
	set rowName [lindex $rowNames $rowIndex]
	set rowVals [lindex $allVals $rowIndex]
	set needVals {}
	foreach colIndex $colIndexes {
	    if {$colIndex != -1} {
		set cellVal [lindex $rowVals $colIndex]
	    } else {
		set cellVal "(missing column)"
	    }
	    lappend needVals $cellVal
	}
	set statValueArray([format "%06d" $rowNum]|$rowName) $needVals
	incr rowNum
    }
    return $rowNum
}

########################################################################################
# Procedure: ::ixTclNet::SendArp
#
# Description: Send ARP to a list of ports
#
# Input arguments
#       vPortList - list of virtual ports to which to send ARP. If the list is empty,
#                   ARP is sent to all available ports
# Output arguments
#       N/A
#
########################################################################################
proc ::ixTclNet::SendArp {{vPortList {}}} {
    if {[llength $vPortList] == 0} {
	set vPortList [ixNet getList [::ixNet getRoot] vport ]
    }

    foreach vPort $vPortList {
	set interfaceList [::ixNet getList $vPort interface]

	foreach interface $interfaceList {
	    ixNet exec sendArp $interface
	}
    }

    # check discovered neighbors
    foreach vPort $vPortList {
	set assignInfo [::ixTclNet::GetAssignmentInfo [list $vPort]]
	set portInfo [lindex $assignInfo 0]
	scan $portInfo "%s %s %s" chassisId cardId portId
	puts "chassis=$chassisId, card=$cardId, port=$portId"
	#interfaceTable get $chassisId $cardId $portId
    }
}

########################################################################################
# Procedure: ::ixTclNet::ApplyTraffic
#
# Description: Apply stream traffic. This call also automatically refreshes learned info.
#
# Input arguments
#       vPortList - list of virtual ports to which to send ARP. If the list is empty,
#                   ARP is sent to all available ports
# Output arguments
#       N/A
# Notes:
#       You many need to add addtional time delay after calling this function before
#       proceeding to other operations. The needed time delay depends on system performance.
########################################################################################
proc ::ixTclNet::ApplyTraffic {} {
    ixNet setAttribute [ixNet getRoot]/traffic -refreshLearnedInfoBeforeApply true
    ixNet commit

    ixNet exec apply [ixNet getRoot]/traffic

    CheckTrafficState stopped
}

########################################################################################
# Procedure: ::ixTclNet::GetTrafficItemList
#
# Description: Get all traffic items
#
# Input arguments
#       N/A
# Output arguments
#       A list of traffic items
########################################################################################
proc ::ixTclNet::GetTrafficItemList {} {
    set tList [ixNet getList [::ixNet getRoot]/traffic trafficItem ]
    return $tList
}

########################################################################################
# Procedure: ::ixTclNet::CheckTrafficState
#
# Description: Check the /traffic -state attribute for non-legacy traffic publisher
#
# Input arguments
#       desiredTrafficState - return true when -state attribute equals this
#       timeout - after this period timeout this operation and return false
# Output arguments
#       N/A
########################################################################################
proc ::ixTclNet::CheckTrafficState {desiredTrafficState {timeout 90000}} {
    set attempts 0
    set waitInterval 2000
    set isLegacyTrafficPublisher [IsLegacyTrafficPublisher]
    if {$isLegacyTrafficPublisher} {
	set timeout 30000
    }

    while {true} {
	after $waitInterval
	update idletasks
	incr attempts
	if {[expr $attempts * $waitInterval] > $timeout} {
	    return false
	}

	if {!$isLegacyTrafficPublisher} {
	    set currentState [ixNet getAttribute [ixNet getRoot]traffic -state]
	    switch $currentState {
		"error" {
		    return false
		}
		default {
		    if {$currentState == $desiredTrafficState} {
			return true
		    }
		}
	    }
	}
    }
}

########################################################################################
# Procedure: ::ixTclNet::StartTraffic
#
# Description: Start traffic for a specified list of traffic items or those already enabled
#              traffics
#
# Input arguments
#       trafficItemList - a list of traffic items to be started. If this list is empty,
#                         stream traffic items which are already enabled are started
# Output arguments
#       N/A
########################################################################################
proc ::ixTclNet::StartTraffic {{trafficItemList {}}} {
    if {[IsLegacyTrafficPublisher]} {
	ixNet exec start [::ixNet getRoot]/traffic
    } else {
	if {[llength $trafficItemList] > 0} {
	    ixNet exec startStatelessTraffic $trafficItemList
	} else {
	    ixNet exec startStatelessTraffic [list [::ixNet getRoot]/traffic]
	}
    }

    CheckTrafficState started 90000
}

########################################################################################
# Procedure: ::ixTclNet::StopTraffic
#
# Description: Stop all running stream traffic
#
# Input arguments
#       N/A
# Output arguments
#       N/A
# Notes:
#      Additional time delay may need based on system performance
########################################################################################
proc ::ixTclNet::StopTraffic {} {
    if {[IsLegacyTrafficPublisher]} {
	ixNet exec stop [::ixNet getRoot]/traffic
    } else {
	ixNet exec stopStatelessTraffic [list [::ixNet getRoot]/traffic]
    }

    CheckTrafficState stopped
}

########################################################################################
# Procedure: ::ixTclNet::GetPageCount
#
# Description: Get total page count for a specific view
#
# Input arguments
#       viewCaption - caption of the stats view
# Output arguments
#       N/A
# Return
#      Total count of the pages for the specified view
########################################################################################
proc ::ixTclNet::GetPageCount {viewCaption} {
    set statObject [::ixTclNet::GetViewObjRef $viewCaption]
    return [::ixNet getAttribute $statObject -totalPages]
}

########################################################################################
# Procedure: ::ixTclNet::GetPageSize
#
# Description: Get the page size for a specified view
#
# Input arguments
#       viewCaption - caption of the stats view
# Output arguments
#       N/A
# Return
#      Page size
########################################################################################
proc ::ixTclNet::GetPageSize {viewCaption} {
    set statObject [::ixTclNet::GetViewObjRef $viewCaption]
    return [ixNet getAttribute $statObject -pageSize]
}

########################################################################################
# Procedure: ::ixTclNet::SetPageSize
#
# Description: Stop all running stream traffic
#
# Input arguments
#       viewCaption - caption of the stats view
#       newPageSize - the desired page size to be set. Note that if the new page size is
#                     larger than the total number of rows, the page size will be
#                     set to the total number of rows.
# Output arguments
#       N/A
# Return
#      The page size newly set
########################################################################################

proc ::ixTclNet::SetPageSize {viewCaption newPageSize} {
    set statObject [::ixTclNet::GetViewObjRef $viewCaption]
    ixNet setAttribute $statObject -pageSize $newPageSize
    ixNet commit
    return [ixNet getAttribute $statObject -pageSize]

}

########################################################################################
# Procedure: ::ixTclNet::SetLineRate
#
# Description: Set the line rate for all traffic items
#
# Input arguments
#       lineRate - The line rate to be set
# Output arguments
#       N/A
# Return
#       N/A
########################################################################################
proc ::ixTclNet::SetLineRate {lineRate} {
    set trafficItems [::ixNet getList [::ixNet getRoot]traffic trafficItem]
    foreach {trafficItem} $trafficItems {
	::ixNet setAttribute $trafficItem/rateOptions -lineRate $lineRate
    }
    ::ixNet commit
}

########################################################################################
# Procedure: ::ixTclNet::SetFrameSize
#
# Description: Set the framesize for all traffic items
#
# Input arguments
#       framesize - The frame size to be set
#
# Output arguments
#       N/A
# Return
#      N/A
########################################################################################
proc ::ixTclNet::SetFrameSize {framesize} {
    if {[IsLegacyTrafficPublisher]} {
	set trafficItems [::ixNet getList [::ixNet getRoot]traffic trafficItem]
	foreach {trafficItem} $trafficItems {
	    ::ixNet setAttribute $trafficItem/frameOptions/fixed -fixedFrameSize $framesize
	}
	::ixNet commit
    } else {
	foreach {trafficItem} [::ixNet getList [::ixNet getRoot]traffic trafficItem] {
	    foreach {configElement} [::ixNet getList $trafficItem configElement] {
		::ixNet setAttribute $configElement/frameSize -fixedSize $framesize
	    }
	    foreach {highLevelStream} [::ixNet getList $trafficItem highLevelStream] {
		::ixNet setAttribute $highLevelStream/frameSize -fixedSize $framesize
	    }
	}
	::ixNet commit
    }
}

########################################################################################
# Procedure: ::ixTclNet::IsLegacyTrafficPublisher
#
# Description: Determines whether or not the current /traffic publisher being used
#              is legacy or not. This is determined by examining the -version flag
#              supplied by the client in the ixNet connect command
#
# Input arguments
#       N/A
#
# Output arguments
#       N/A
# Return
#      true if legacy traffic publisher is being used else false
########################################################################################
proc ::ixTclNet::IsLegacyTrafficPublisher {} {
    array set sessionParameters [::ixNet setSessionParameters]
    set versionList [split $sessionParameters(publisherVersion) .]

    if {[lindex $versionList 0] < 5} {
	return true
    }
    if {[lindex $versionList 0] == 5 && [lindex $versionList 1] < 40} {
	return true
    }

    return false
}

########################################################################################
# Procedure: ::ixTclNet::ClearOwnershipForAllPorts
#
# Description: Clear ownership for all virtual ports
#
# Input arguments
#       N/A
#
# Output arguments
#       N/A
# Return
#      N/A
########################################################################################
proc ::ixTclNet::ClearOwnershipForAllPorts {} {
    foreach vPortObject [ixNet getList [ixNet getRoot] vport ] {
	set portObject [ixNet getAttribute $vPortObject -connectedTo]
	ixNet exec clearOwnership $portObject
    }
}

########################################################################################
# Procedure: ::ixTclNet::ConnectPorts
#
# Description: Connect to a list of ports.
#
# Input arguments
#       vPortList - List of the virtual ports to be connected. If this is empty,
#                   all virtual ports will be connected.
#
# Output arguments
#       N/A
# Return
#      N/A
# Notes:
#      It is assumed that the virtual ports have been assigned physical ports
#      before calling this fucntion
########################################################################################
proc ::ixTclNet::ConnectPorts {{vPortList {}}} {
    if {[llength $vPortList] == 0} {
	set vPortList [ixNet getList [::ixNet getRoot] vport]
    }
    ixNet exec connectPorts $vPortList
}

########################################################################################
# Procedure: ::ixTclNet::ReleasePorts
#
# Description: Release a list of ports
#
# Input arguments
#       vPortList - list of the virtual ports to be released. If this list is empty,
#                   all ports are released
#
# Output arguments
#       N/A
# Return
#      N/A
########################################################################################
proc ::ixTclNet::ReleasePorts {{vPortList {}}} {
    if {[llength $vPortList] == 0} {
	set vPortList [ixNet getList [::ixNet getRoot] vport ]
    }
    foreach vPort $vPortList {
	ixNet exec releasePort $vPort
    }
}

########################################################################################
# Procedure: ::ixTclNet::StartProtocols
#
# Description: Start a list of protocols on a list of ports
#
# Input arguments
#       protocolNameList  - list of protocol names. The default list is:
#                           bfd bgp eigrp igmp isis ldp mld ospf ospfV3 pimsm ping rip ripng rsvp static stp
#       vPortList - list of virtual ports to start protocols. If it is empty, specified protocols are started
#                   on all virtual ports
# Output arguments
#       N/A
# Return
#      N/A
########################################################################################
proc ::ixTclNet::StartProtocols {{protocolNameList {bfd bgp eigrp igmp isis ldp mld ospf ospfV3 pimsm ping rip ripng rsvp static stp}} {vPortList {}}} {
    if {[llength $vPortList] == 0} {
	set vPortList [ixNet getList [::ixNet getRoot] vport ]
    }

    foreach vPort $vPortList {
	foreach protocolName $protocolNameList {
	    #puts "protocolName = $protocolName"
	    ixNet exec start $vPort/protocols/$protocolName
	}
    }
}

########################################################################################
# Procedure: ::ixTclNet::StopProtocols
# Description: Stop a list of protocols on a list of ports
# Input arguments
#       protocolNameList  - list of protocol names. The default list is:
#                           bfd bgp eigrp igmp isis ldp mld ospf ospfV3 pimsm ping rip ripng rsvp static stp
#       vPortList - list of virtual ports to start protocols. If it is empty, specified protocols are started
#                   on all virtual ports
# Output arguments
#       N/A
# Return
#      N/A
########################################################################################
proc ::ixTclNet::StopProtocols {{protocolNameList {bfd bgp eigrp igmp isis ldp mld ospf ospfV3 pimsm ping rip ripng rsvp static stp}} {vPortList {}}} {
    if {[llength $vPortList] == 0} {
	set vPortList [ixNet getList [::ixNet getRoot] vport ]
    }

    foreach vPort $vPortList {
	foreach protocolName $protocolNameList {
	    ixNet exec stop $vPort/protocols/$protocolName
	}
    }
}

#####################################################################
# Helper: Reformat row name by removing "0" before card and ports
#####################################################################
proc ::ixTclNet::reformatRowName { rowName } {
    set splitString [split $rowName /]
    set hostName [lindex $splitString 0]
    set card     [string trimleft [lindex $splitString 1] "Card"]
    set port     [string trimleft [lindex $splitString 2] "Port"]
    # Trim "0" before numbers
    set card [expr $card*1]
    set port [expr $port*1]
    return "$hostName/$card/$port"
}

########################################################################################
# Procedure: ::ixTclNet::AssignPorts
#
# Description: Attempts to assign the list of real port to the list of vports. If the
#               vport list is empty, the vport will be added. it connects to chassis if needed
#               and checks the link state on the port after assignment.
#
# Arguments: realPortList           - A list of real ports in the format of
#                                        {{hostname1 cardNumber portNumber}} or wildcards
#            excludePortList        - Exclude ports if wildcard format is used.
#            vportObjRefList        - vport objRef list to be assigned the the real
#                                        ports. (in the same order)
#            forcedClearOwnership   - Forced clear ownership when it is "true".
# 			 timeoutCount: 			- In seconds. When to give up if could not connect to all chassis
#
#
# Returns: list of vport objRefs now assigned to this list of real ports
########################################################################################

proc ::ixTclNet::AssignPorts { realPortList {excludePortList {}} {vportObjRefList ""} {forcedClearOwnership false} {timeoutCount 1000}} {
    # hack to transform from random string to bool
    if {$forcedClearOwnership != "false"} {
		set forcedClearOwnership "true"
    }  

    # assign the ports using the exec
    set vportObjRefList [ixNet -strip exec assignPorts $realPortList $excludePortList $vportObjRefList $forcedClearOwnership]

    # for backward compatibility return
    ::ixTclNet::CheckLinkState $vportObjRefList doneList
    return $vportObjRefList
}

########################################################################################
# Procedure: ::ixTclNet::UnassignPorts
#
# Description:  Unassign a list of  virtual ports.

# Arguments: vportObjRefList  - A list of virtual port object ref. If this list is empty,
#                               all virtual ports are unassigned.
#            removeVports     - When it is true, it removes the vports too.
#
#
# Returns: A return code of 0 for success and 1 for error.
########################################################################################
proc ::ixTclNet::UnassignPorts { {vportObjRefList ""} {removeVports false} } {

    set retCode 0
    if {[llength $vportObjRefList] == 0} {
	set vportObjRefList [ ixNet getList [ixNet getRoot] vport ]
    }
    if {$removeVports == "true"} {
	foreach vportRef $vportObjRefList {
	    ixNet remove $vportRef
	}
    } else {
	foreach vport $vportObjRefList {
	    ixNet setAttribute $vport -connectedTo  [ixNet getNull]
	}
    }

    #wait until ports are unlocked
    set waitCount 1
    set timeoutCount 60

    while {$waitCount < $timeoutCount} {
	if {[ixNet getAttribute [ixNet getRoot]/availableHardware -isLocked] == false} {
	    break;
	}
	incr waitCount
	after 1000
    }

    ixNet -timeout 0 commit
    return $retCode
}

########################################################################################
# Procedure: ::ixTclNet::CheckLinkState
#
# Description:  Checks the port link state.

# Arguments: vportObjRefList  - A list of vport objRef
#            PortsToRemove    - List of ports that are not in desired state. (optional)
#            desiredStatus    - kBusy kDown kUnassigned kUp
#            timeout          - how long to wait before giving up
#
# Returns: A return code of 0 for success and 1 for error.
########################################################################################

proc ::ixTclNet::CheckLinkState { vportObjRefList {PortsToRemove ""} {desiredStatus up} {timeout 60}} {

    upvar $PortsToRemove portsToRemove
    set retCode 0

    if {[info exists linkState]} {
	unset linkState
    }

    after 1000  ;# give the port some time to begin it's in autonegotiate mode or PPP

    set portList    $vportObjRefList

    # go through all the ports and label the ones whose links are not as desieredStatus
    foreach vport $portList {
	if {![info exists linkState($vport)]} {
	    set state   [ixNet getAttribute $vport -state]
	    if {$state != $desiredStatus } {
		set linkState($vport)	$state
	    }
	    if { $state == "up" && [ixNet getAttribute $vport -isConnected] == "false" } {
		set linkState($vport)	$state
	    }
	}
    }

    # the linkState array are all the ports whose links are not desired. Now poll
    # them a few times until they are all desired or return.
    set loopCount   [expr $timeout * 2]
    for {set ctr 0} {$ctr < $loopCount} {incr ctr} {
	foreach downlink [array names linkState] {
	    set state   [ixNet getAttribute $downlink -state]
	    if {$state == $desiredStatus } {
		if { $state == "up" && [ixNet getAttribute $downlink -isConnected] == "false" } {
		    continue
		}
		unset linkState($downlink)
	    }
	}
	if {[llength [array names linkState]] == 0} {
	    break
	} else {
	    after 500
	}
    }

    set portsToRemove [array names linkState]

    #wait for stats to become populated
    set count 0
    if {$desiredStatus == "up"} {
	while { [llength [ixNet getList [ixNet getRoot]statistics view]] == 0 } {
	    after 1000
	    if { [incr count ] == 60 } {
		error "Stats were not ready after $count seconds"
	    }
	}
    }

    if {[llength [array names linkState]] == 0} {
	puts "Links on all ports are up."
    } else {
	puts "Link on these ports are:"
	foreach downlink [array names linkState] {
	    puts "$downlink : $linkState($downlink)"
	}
	set retCode 1
    }

    return $retCode
}

########################################################################################
# Procedure: ::ixTclNet::GetAssignmentInfo
#
# Description:  Gets the connection info for each vport. If it is unassigned, returns
#               null list.

# Arguments: vportObjRefList  - vport objRef list
#
#
# Returns: list of real ports {{ip card port} {}} in the same order of vport list.
########################################################################################
proc ::ixTclNet::GetAssignmentInfo { vportObjRefList } {

    set retList {}
    foreach vport $vportObjRefList {
	set realPortObjRef   [ixNet getAttribute $vport -connectedTo]
	if {$realPortObjRef != [ixNet getNull]} {
	    set portId [ixNet getAttribute $realPortObjRef -portId]

	    set cardObjRef [ixNet getParent $realPortObjRef]
	    set cardId [ixNet getAttribute  $cardObjRef -cardId]

	    set chassisObjRef [ixNet getParent $cardObjRef]
	    set chassisIp     [ixNet getAttribute $chassisObjRef -hostname]

	    set retPort [list $chassisIp $cardId $portId]
	    lappend retList $retPort
	} else {
	    lappend retList {}
	}
    }
    return $retList
}

########################################################################################
# Procedure: ::ixTclNet::FindAssignedVports
#
# Description:  Gets the vport objRef for each real port.

# Arguments: portList       - A list of real ports in the format of {{hostname1 cardNumber portNumber}}
#                               or wildcards {{hostname1 cardNumber *}}
#           excludePortList - Exclude ports if wildcard format is used.
#
# Returns: List of vports and the real ports {{hostname 1 2} ::ixNet::OBJ-/vport:3}}
########################################################################################
proc ::ixTclNet::FindAssignedVports  {portList {excludePortList ""}} {
    set retList {}

    set realPortList [::ixTclNet::CreatePortListWildCard $portList $excludePortList]

    set vportList [ixNet getList [ixNet getRoot] vport]

    foreach realPort $realPortList {
	#find objRef of real port.
	scan [join $realPort] "%s %d %d" hostname card_id port_id
	set realPortObjRef [::ixTclNet::GetRealPortObjRef $hostname $card_id $port_id]

	if {$realPortObjRef != ""} {
	    set vport [ixNet getFilteredList [ixNet getRoot] vport -connectedTo $realPortObjRef]
	    lappend retList [list [list $hostname $card_id $port_id] $vport]
	}
    }

    return $retList
}

########################################################################################
# Procedure: ::ixTclNet::MultiGetAttribute
#
# Description:  Gets the value of attributes for a list of objectRef.

# Arguments: objRefList  - object ref list.
#            optionList  - list of desired options {-state -type}. if null it returns all
#                           options.
#
#
#
# Returns: list of lists of attributes
########################################################################################
proc ::ixTclNet::MultiGetAttribute   {objRefList optionList} {
    set retList {}

    foreach item $objRefList {
	if {[llength $optionList] > 0} {
	    set retOptionVal {}
	    foreach option $optionList {
		if {[string index $option 0] != "-"} {
		    set option -$option
		}
		lappend retOptionVal [ixNet getAttribute $item $option]
	    }
	}
	lappend retList $retOptionVal
    }
    return $retList
}

########################################################################################
# Procedure: ::ixTclNet::MultiSetAttribute
#
# Description:  Sets the value of attributes for a list of objectRef. "commit" command needs
#                to be called after MultiSetAttribute.
#
# Arguments: objRefList  - object ref list.
#            optionList  - list of desired options and their values {{-fullDuplex  true} {-speed 100}}
#
#
#
# Returns: void
########################################################################################
proc ::ixTclNet::MultiSetAttribute   {objRefList optionList} {
    foreach item $objRefList {
	if {[llength $optionList] > 0} {
	    foreach {option value} [join $optionList] {
		ixNet setAttribute $item $option $value
	    }
	}
    }
}

########################################################################################
# Procedure: ::ixTclNet::BrowseWizard
#
# Description: An interactive command-line script to navigate the traffic wizard and
#              select endpoints
#
# Arguments: startPoint             - starting point for wizard, should be src or dst
#            chan                   - optional channel to use for input (default stdin)
#
#
# Returns: list of traffic ids, suitable to setAttribute the -src or -dst attribute of
#          a /traffic/trafficItem/pair object
#
########################################################################################
proc ::ixTclNet::BrowseWizard { startPoint { chan stdin } } {
    puts "deprecated proc"
    set curId [ixNet getRoot]/traffic/wizard/$startPoint
    if { ![ixNet exists $curId] } {
	if { ![string equal $startPoint src] && ![string equal $startPoint dst] } {
	    error "$curId does not exist, try passing src or dst to ::ixTclNet::BrowseWizard"
	} else {
	    error "$curId does not exist, check your connection"
	}
    }
    puts "# browse traffic wizard (type ? for help)"
    set curAccum [list]
    set curChildren [ixNet getList $curId node]
    while { [gets $chan line] >= 0 } {
	set invals [split [string trim $line] " "]
	switch [lindex $invals 0] {
	    q	-
	    quit	{ break }
	    u	-
	    up	{
		set curId [ixNet getParent $curId]
		set curChildren [ixNet getList $curId node]
	    }
	    d	-
	    down	{
		set index [lindex $invals 1]
		if { ![string is integer -strict $index] } {
		    puts "# non-integer $index passed to down"
		} else {
		    set curId [lindex $curChildren $index]
		    set curChildren [ixNet getList $curId node]
		}
	    }
	    refresh	{
		set curChildren [ixNet getList $curId node]
	    }
	    a	-
	    add	{
		set nArgs [llength $invals]
		if { $nArgs > 1 } {
		    for {set x 1} { $x<$nArgs } {incr x} {
			set index [lindex $invals $x]
			if { ![string is integer -strict $index] } {
			    puts "# non-integer $index passed to add"
			} else {
			    set addedIds [ixNet getAttribute [lindex $curChildren $index] -id]
			    foreach id $addedIds {
				lappend curAccum $id
			    }
			}
		    }
		} else {
		    set addedIds [ixNet getAttribute $curId -id]
		    foreach id $addedIds {
			lappend curAccum $id
		    }
		}
	    }
	    show	{
		puts "# current location: traffic id [ixNet getAttribute $curId -trafficId] (wizard id $curId)"
		puts "# id: [ixNet getAttribute $curId -id]"
		puts "# children:"
		set nChildren [llength $curChildren]
		for {set x 0} { $x<$nChildren } {incr x} {
		    puts "#\t$x: [ixNet getAttribute [lindex $curChildren $x] -name]"
		}
		puts "# selection: $curAccum"
	    }
	    set	{
		if { [llength $invals] > 1 } {
		    upvar [lindex $invals 1] myAssign
		    set myAssign $curAccum
		    puts "# set [lindex $invals 1] $curAccum"
		} else {
		    puts "# no variable name passed to assign"
		}
	    }
	    clear	{
		set curAccum [list]
	    }
	    src	{
		set curId [ixNet getRoot]/traffic/wizard/src
		set curChildren [ixNet getList $curId node]
	    }
	    dst	{
		set curId [ixNet getRoot]/traffic/wizard/dst
		set curChildren [ixNet getList $curId node]
	    }
	    ?	-
	    h	-
	    help	-
	    default	{
		puts "# help for ::ixTclNet::BrowseWizard:"
		puts "# show: show current location, children, and selection"
		puts "# up: change current location to current location's parent"
		puts "# down 2: change current location to current location's child(2)"
		puts "# add: add current location to selection"
		puts "# add 1 5 7 ...: add child indexes 1, 5, 7, ... to selection"
		puts "# clear: clear selection"
		puts "# src: change location to /traffic/wizard/src"
		puts "# dst: change location to /traffic/wizard/dst"
		puts "# set myName: set current selection into variable myName"
		puts "# refresh: retrieve children for current location again"
		puts "# quit: quit BrowseWizard (returns current selection)"
	    }
	}
    }
    return $curAccum
}

########################################################################################
# Procedure: ::ixTclNet::LookupTrafficFromStatisticsRow
#
# Description:  Finds the related traffic item and flow from a row in the statistics.
#
# Arguments: statRowObjref         - object ref to a statistics row:
#                            /statistics/trafficStatViewBrowser:"Traffic Statistics"/row:XXX
#
#            VAR_trafficItemObjref - variable name to place the traffic item objref
#            VAR_flowName          - variable name to place the flow name
#
# Returns: void
########################################################################################
proc ::ixTclNet::LookupTrafficFromStatisticsRow { statRowObjref VAR_trafficItemObjref VAR_flowName } {
    puts "deprecated proc"

    # attach to vars
    upvar $VAR_trafficItemObjref trafficItem
    upvar $VAR_flowName flowName

    # parse .name
    set name [::ixNet getAtt $statRowObjref -name]
    set splits [split $name '|']

    # splits[0]= trafficItemName (00000-0000)
    # splits[1]= pgid
    # splits[2]= rx port label
    # splits[3]= flow label
    # splits[4]= tx port label

    # remove stream ids
    set tin [lindex $splits 0]
    set lastParen [expr [string last " (" $tin]-1]
    set tin [string range $tin 0 $lastParen]

    # find that traffic item
    set tiList [::ixNet getFilteredList [::ixNet getRoot]/traffic/trafficItems item -name $tin]

    #### workaround for getFilteredList bug 115035
    if { [llength $tiList] != 1 } {
	set theGoodOne {}
	foreach ti $tiList {
	    if { [string equal [::ixNet getAtt $ti -name] $tin] } {
		set theGoodOne $ti
		break
	    }
	}
	set tiList $theGoodOne
    }
    #### workaround for getFilteredList bug 115035

    # ok?
    if { [llength $tiList] != 1 } {
	error "No matching traffic configuration found for this statistics row"
    }

    # pass result thru args
    set trafficItem [lindex $tiList 0]
    set flowName [lindex $splits 3]
}

########################################################################################
# Procedure: ::ixTclNet::LookupStatisticsRowsFromTrafficEndpointPair
#
# Description:  Finds the statistics rows that can be combined for the requested flow
#
# Arguments: trafficItemObjref  - object ref to a traffic item
#            srcFlowValue       - first value from source endpoint (example: "1.1.1.1")
#            destFlowValue      - first value from dest endpoint (example: "2.2.2.2")
#            rxPortObjref       - object ref to the rx port of the flow (optional)
#
# Returns: objref list of stat rows
########################################################################################
proc ::ixTclNet::LookupStatisticsRowsFromTrafficEndpointPair { trafficItemObjref srcFlowValue destFlowValue {rxPortObjref "all"} } {
    puts "deprecated proc"

    # request flow label
    set flowLabelStr [::ixNet exec generateFlowLabel $trafficItemObjref $srcFlowValue $destFlowValue]
    if { [string length $flowLabelStr] < 22 } {
	error "can't generate flow label"
    }

    # strip ::ixNet::OK-{kString,FLOWLABEL}
    set flowLabelStr [string range $flowLabelStr 21 end-1]

    # do it
    return [LookupStatisticsRowsFromTrafficFlowLabel $trafficItemObjref $flowLabelStr $rxPortObjref]
}

########################################################################################
# Procedure: ::ixTclNet::LookupStatisticsRowsFromTraffic
#
# Description:  Finds the statistics rows that can be combined for the requested flow
#
# Arguments: trafficItemObjref  - object ref to a traffic item
#            flowValue          - value of flow to find (example: "1.2.3.4")
#            rxPortObjref       - object ref to the rx port of the flow (optional)
#
# Returns: objref list of stat rows
########################################################################################
proc ::ixTclNet::LookupStatisticsRowsFromTraffic { trafficItemObjref flowValue {rxPortObjref "all"} } {
    puts "deprecated proc"

    # request flow label
    set flowLabelStr [::ixNet exec generateFlowLabel $trafficItemObjref $flowValue]
    if { [string length $flowLabelStr] < 22 } {
	puts $flowLabelStr
	error "can't generate flow label"
    }

    # strip ::ixNet::OK-{kString,FLOWLABEL}
    set flowLabelStr [string range $flowLabelStr 21 end-1]

    # do it
    return [LookupStatisticsRowsFromTrafficFlowLabel $trafficItemObjref $flowLabelStr $rxPortObjref]
}

# Internal helper function
proc ::ixTclNet::LookupStatisticsRowsFromTrafficFlowLabel { trafficItemObjref flowLabelStr {rxPortObjref "all"} } {
    puts "deprecated proc"

    # get traffic name from objref
    set trafficItemName [::ixNet getAtt $trafficItemObjref -name]

    # get port label from objref
    if { ! [string equal $rxPortObjref "all"] } {
	set rxPortLabel [::ixNet getAtt $rxPortObjref -name]
    } else {
	set rxPortLabel {}
    }

    # create ref to our trafficStatViewBrowser
    set svb [lindex [ixNet getList [::ixNet getRoot]/statistics trafficStatViewBrowser] 0]

    # enable traffic view + commit, if not already
    if { ! [::ixNet getAtt $svb -enabled] } {
	::ixNet setAtt $svb -enabled true
	::ixNet commit

	# wait for view to become ready, with extra waiting when we had to enable the view
	if { ! [::ixTclNet::isStatsReady $svb 300] } {
	    error "Timeout in 300 seconds while waiting for traffic view to be ready"
	}
    }

    # wait for view to become ready
    if { ! [::ixTclNet::isStatsReady $svb 300] } {
	error "Timeout in 300 seconds while waiting for traffic view to be ready"
    }
    # init list
    set objrefs {}

    # start on page 1, loop each page
    set totalPages [::ixNet getAtt $svb -totalPages]
    for {set currentPage 1} { $currentPage <= $totalPages } {incr currentPage} {

	# move to requested page
	if { $currentPage != [::ixNet getAtt $svb -currentPageNumber] } {
	    ::ixNet setAtt $svb -currentPageNumber $currentPage
	    ::ixNet commit

	    # wait for view to become ready, with extra waiting when we had to switch pages
	    if { ! [::ixTclNet::isStatsReady $svb 300] } {
		error "Timeout in 300 seconds while waiting for traffic view to be ready"
	    }
	}

	# loop /statistics/trafficStatViewBrowser:"Traffic Statistics"/row
	set rowList [::ixNet getList $svb row]
	foreach row $rowList {

	    # parse .name
	    set name [::ixNet getAtt $row -name]
	    set splits [split $name "|"]

	    # splits[0]= trafficItemName (00000-0000)
	    # splits[1]= pgid
	    # splits[2]= rx port label
	    # splits[3]= flow label
	    # splits[4]= tx port label

	    # remove stream ids
	    set tin [lindex $splits 0]
	    set lastParen [expr [string last " (" $tin]-1]
	    set tin [string range $tin 0 $lastParen]

	    # if match against args, add to list
	    set isTI [string equal $tin $trafficItemName]
	    set isFlow [string equal -nocase [lindex $splits 3] $flowLabelStr]
	    if { [expr $isTI && $isFlow] } {

		# rx port filter
		if { [string length $rxPortLabel] != 0 } {
		    if { ! [string equal [lindex $splits 2] $rxPortLabel] } {
			continue
		    }
		}

		lappend objrefs $row
	    }
	}
    }

    # return list
    return $objrefs;
}

########################################################################################
# Procedure: ::ixTclNet::RetrieveTrafficStatistics
#
# Description:  Combine the requested rows to get the aggregated statistics. Use this on
#               the list returned from LookupStatisticsRowsFromTraffic.
#
# Arguments: statRowObjrefs  - list of object ref to a statistics rows
#
# Returns: list of name value pairs (array get syntax)
########################################################################################
proc ::ixTclNet::RetrieveTrafficStatistics { statRowObjrefs } {
    puts "deprecated proc"

    array set result {}
    array set avgCount {}

    # create ref to our trafficStatViewBrowser
    set svb [lindex [ixNet getList [::ixNet getRoot]/statistics trafficStatViewBrowser] 0]

    # make sure it is enabled and ready
    if { ! [::ixNet getAtt $svb -enabled] } {
	error "traffic statistics view must be enabled to retrieve statistics";
    }
    if { ! [::ixNet getAtt $svb -isReady] } {
	error "traffic statistics view must be ready to retrieve statistics";
    }

    # get number of stats per page
    set statsPerPage [::ixNet getAtt $svb -pageSize]

    # retrieve each row
    foreach row $statRowObjrefs {

	# what page is it on?
	set lastColonIndex [string last ":" $row]
	set rowIndex [string range $row [expr $lastColonIndex + 1] end]
	set statPage [expr ($rowIndex / $statsPerPage)+1]

	# switch to the correct page
	if { $statPage != [::ixNet getAtt $svb -currentPageNumber] } {
	    ::ixNet setAtt $svb -currentPageNumber $statPage
	    ::ixNet commit

	    # wait for view to become ready, with extra waiting when we had to switch pages
	    ::ixTclNet::WaitForTrafficViewReady $svb
	}

	# combine the values
	foreach cell [::ixNet getList $row cell] {
	    set cellValue [::ixNet getAtt $cell -statValue]
	    if { [string equal "" $cellValue] } { continue }

	    set columnName [::ixNet getAtt $cell -columnName]

	    ::ixTclNet::AggregateValue result avgCount $columnName $cellValue
	}
    }

    # fixup average columns
    ::ixTclNet::CollapseAverages result avgCount

    # return the result
    return [array get result]
}

# internal helper function
proc ::ixTclNet::AggregateValue { upResultName upAvgCountName columnName cellValue } {
    upvar $upResultName result
    upvar $upAvgCountName avgCount

    set oldPair [array get result $columnName]

    if { [llength $oldPair] == 0 } {
	# new cell, just take it
	array set result [list $columnName $cellValue]
	array set avgCount [list $columnName 1]
    } else {
	set oldValue [lindex $oldPair 1]
	switch $columnName {
	    {Max Latency (ns)} {
		# MAX
		if { $cellValue > $oldValue } {
		    set newValue $cellValue
		} else {
		    set newValue $oldValue
		}
	    }
	    {Min Latency (ns)} {
		# MIN
		if { $cellValue < $oldValue } {
		    set newValue $cellValue
		} else {
		    set newValue $oldValue
		}
	    }
	    {Frames Delta} -
	    {Rx Bytes} -
	    {Rx Frames} -
	    {Tx Frames} {
		# SUM
		set newValue [expr $cellValue + $oldValue]
	    }
	    {Avg Latency (ns)} -
	    {Rx Frame Rate} -
	    {Rx Rate (Mbps)} -
	    {Tx Frame Rate} -
	    {Rx Rate (Bps)} -
	    {Rx Rate (bps)} -
	    {Rx Rate (Kbps)} -
	    {Loss %} {
		# AVG
		set newValue [expr $cellValue + $oldValue]

		set count [lindex [array get avgCount $columnName] 1]
		incr count
		array set avgCount [list $columnName $count]
	    }
	    {First Timestamp} {
		# MIN, Timestamp (hr:min:sec.ms)
		set oldSplit [split $oldValue ":."]
		# get rid of leading zeros
		for {set i 0} {$i < 4} {incr i} {
		    if { [string equal [lindex $oldSplit $i] "00"] } {
			lset oldSplit $i "0"
		    } elseif { [string length [lindex $oldSplit $i]] > 1 } {
			lset oldSplit $i [string trimleft [lindex $oldSplit $i] "0"]
		    }
		}
		set oldInt [expr [lindex $oldSplit 0]*3600000 + [lindex $oldSplit 1]*60000 + [lindex $oldSplit 2]*1000 + [lindex $oldSplit 3]]
		set newSplit [split $cellValue ":."]
		# get rid of leading zeros
		for {set i 0} {$i < 4} {incr i} {
		    if { [string equal [lindex $newSplit $i] "00"] } {
			lset newSplit $i "0"
		    } elseif { [string length [lindex $newSplit $i]] > 1 } {
			lset newSplit $i [string trimleft [lindex $newSplit $i] "0"]
		    }
		}
		set newInt [expr [lindex $newSplit 0]*3600000 + [lindex $newSplit 1]*60000 + [lindex $newSplit 2]*1000 + [lindex $newSplit 3]]
		if { $newInt < $oldInt } {
		    set newValue $cellValue
		} else {
		    set newValue $oldValue
		}
	    }
	    {Last Timestamp} {
		# MAX, Timestamp
		set oldSplit [split $oldValue ":."]
		# get rid of leading zeros
		for {set i 0} {$i < 4} {incr i} {
		    if { [string equal [lindex $oldSplit $i] "00"] } {
			lset oldSplit $i "0"
		    } elseif { [string length [lindex $oldSplit $i]] > 1 } {
			lset oldSplit $i [string trimleft [lindex $oldSplit $i] "0"]
		    }
		}
		set oldInt [expr [lindex $oldSplit 0]*3600000 + [lindex $oldSplit 1]*60000 + [lindex $oldSplit 2]*1000 + [lindex $oldSplit 3]]
		set newSplit [split $cellValue ":."]
		# get rid of leading zeros
		for {set i 0} {$i < 4} {incr i} {
		    if { [string equal [lindex $newSplit $i] "00"] } {
			lset newSplit $i "0"
		    } elseif { [string length [lindex $newSplit $i]] > 1 } {
			lset newSplit $i [string trimleft [lindex $newSplit $i] "0"]
		    }
		}
		set newInt [expr [lindex $newSplit 0]*3600000 + [lindex $newSplit 1]*60000 + [lindex $newSplit 2]*1000 + [lindex $newSplit 3]]
		if { $newInt > $oldInt } {
		    set newValue $cellValue
		} else {
		    set newValue $oldValue
		}
	    }
	    default {
		# don't do the set
		return
	    }
	}

	array set result [list $columnName $newValue]
    }
}

# internal helper function
proc ::ixTclNet::CollapseAverages {upResultName upAvgCountName} {
    upvar $upResultName result
    upvar $upAvgCountName avgCount

    foreach {columnName oldValue} [array get result] {
	switch $columnName {
	    {Avg Latency (ns)} -
	    {Rx Frame Rate} -
	    {Rx Rate (Mbps)} -
	    {Tx Frame Rate} -
	    {Rx Rate (Bps)} -
	    {Rx Rate (bps)} -
	    {Rx Rate (Kbps)} -
	    {Loss %} {
		# AVG double

		set count [lindex [array get avgCount $columnName] 1]
		if { $count > 1 } {
		    set newValue [expr $oldValue / $count]
		    array set result [list $columnName $newValue]
		}
	    }
	}
    }
}

########################################################################################
# Procedure: ::ixTclNet::CacheFindStatRowsFromTrafficEndpointPair
#
# Description:  Finds the statistics rows that can be combined for the requested flow
#
# Arguments: trafficItemObjref  - object ref to a traffic item
#            srcFlowValue       - first value from source endpoint (example: "1.1.1.1")
#            destFlowValue      - first value from dest endpoint (example: "2.2.2.2")
#            rxPortObjref       - object ref to the rx port of the flow (optional)
#
# Returns: objref list of stat rows
########################################################################################
proc ::ixTclNet::CacheFindStatRowsFromTrafficEndpointPair { cache trafficItemObjref srcFlowValue destFlowValue {rxPortObjref "all"} } {
    puts "deprecated proc"

    # request flow label
    set flowLabelStr [::ixNet exec generateFlowLabel $trafficItemObjref $srcFlowValue $destFlowValue]
    if { [string length $flowLabelStr] < 22 } {
	error "can't generate flow label"
    }

    # strip ::ixNet::OK-{kString,FLOWLABEL}
    set flowLabelStr [string range $flowLabelStr 21 end-1]

    # do it
    return [CacheFindStatRowsFromTrafficFlowLabel $cache $trafficItemObjref $flowLabelStr $rxPortObjref]
}

########################################################################################
# Procedure: ::ixTclNet::CacheFindStatRowsFromTraffic
#
# Description:  Finds the statistics rows that can be combined for the requested flow
#
# Arguments: trafficItemObjref  - object ref to a traffic item
#            flowValue          - value of flow to find (example: "1.2.3.4")
#            rxPortObjref       - object ref to the rx port of the flow (optional)
#
# Returns: objref list of stat rows
########################################################################################
proc ::ixTclNet::CacheFindStatRowsFromTraffic { cache trafficItemObjref flowValue {rxPortObjref "all"} } {
    puts "deprecated proc"

    # request flow label
    set flowLabelStr [::ixNet exec generateFlowLabel $trafficItemObjref $flowValue]
    if { [string length $flowLabelStr] < 22 } {
	puts $flowLabelStr
	error "can't generate flow label"
    }

    # strip ::ixNet::OK-{kString,FLOWLABEL}
    set flowLabelStr [string range $flowLabelStr 21 end-1]

    # do it
    return [CacheFindStatRowsFromTrafficFlowLabel $cache $trafficItemObjref $flowLabelStr $rxPortObjref]
}

proc ::ixTclNet::isStatsReady {svb timeout} {
    # timeout is in seconds
    set startTime [clock seconds]
    while { ! [::ixNet getAtt $svb -isReady] } {
	set endTime [clock seconds]
	set diff [expr $endTime - $startTime]
	if { $diff > $timeout } {
	    return false
	}
	after 250
    }
    return true
}

proc ::ixTclNet::WaitForTrafficViewReady {svb} {
    # wait for view to become ready
    if { ! [::ixTclNet::isStatsReady $svb 300] } {
	error "Timeout in 300 seconds while waiting for traffic view to be ready"
    }

    #bizarrely, the current behavior sometimes has the wrong set of rows after isReady is true, for a time.
    set hadValue 0
    while {!$hadValue} {
	set rowList [ixNet getList $svb row]
	set row [lindex $rowList 0]
	set cellList [ixNet getList $row cell]
	set cell [lindex $cellList 0]
	set cellValue [ixNet getAttribute $cell -statValue]
	if {$cellValue != ""} {
	    set hadValue 1
	}
    }
}

# builds the cache you pass to CacheFindXXX
proc ::ixTclNet::MakeStatsLookupCache { } {
    puts "deprecated proc"

    # create ref to our trafficStatViewBrowser
    set svb [::ixNet getRoot]/statistics/trafficStatViewBrowser:"Traffic\ Statistics"

    # enable traffic view + commit, if not already
    if { ! [::ixNet getAtt $svb -enabled] } {
	::ixNet setAtt $svb -enabled true
	::ixNet commit
    }

    ::ixTclNet::WaitForTrafficViewReady $svb

    set totalPages [::ixNet getAtt $svb -totalPages]
    set origPage [ixNet getAttribute $svb -currentPageNumber]

    set cache [list]

    #start on current page
    set rowList [ixNet getList $svb row]
    foreach row $rowList {
	set name [ixNet getAttribute $row -name]
	lappend cache [list $name $row]
    }

    set origPageCache $cache
    set cache [list]

    set currentPage 1
    while {$currentPage < $origPage} {
	::ixNet setAtt $svb -currentPageNumber $currentPage
	::ixNet commit

	::ixTclNet::WaitForTrafficViewReady $svb

	set rowList [ixNet getList $svb row]
	foreach row $rowList {
	    set name [ixNet getAttribute $row -name]
	    lappend cache [list $name $row]
	}
	incr currentPage
    }

    # already did origPage, but let's keep them in order just for kicks
    foreach rowPair $origPageCache { lappend cache $rowPair }
    incr currentPage

    while {$currentPage <= $totalPages} {
	::ixNet setAtt $svb -currentPageNumber $currentPage
	::ixNet commit

	::ixTclNet::WaitForTrafficViewReady $svb

	set rowList [ixNet getList $svb row]
	foreach row $rowList {
	    set name [ixNet getAttribute $row -name]
	    lappend cache [list $name $row]
	}
	incr currentPage
    }

    return $cache
}

# Internal helper function
proc ::ixTclNet::CacheFindStatRowsFromTrafficFlowLabel { cache trafficItemObjref flowLabelStr {rxPortObjref "all"} } {
    puts "deprecated proc"

    # get traffic name from objref
    set trafficItemName [::ixNet getAtt $trafficItemObjref -name]

    # get port label from objref
    if { ! [string equal $rxPortObjref "all"] } {
	set rxPortLabel [::ixNet getAtt $rxPortObjref -name]
    } else {
	set rxPortLabel {}
    }

    # create ref to our trafficStatViewBrowser
    set svb [::ixNet getRoot]/statistics/trafficStatViewBrowser:"Traffic\ Statistics"

    # enable traffic view + commit, if not already
    if { ! [::ixNet getAtt $svb -enabled] } {
	::ixNet setAtt $svb -enabled true
	::ixNet commit
    }

    ::ixTclNet::WaitForTrafficViewReady $svb

    # init list
    set objrefs {}

    # go thru the cache and find matches from the row name
    foreach cacheEntry $cache {

	set name [lindex $cacheEntry 0]
	set row [lindex $cacheEntry 1]

	# parse .name
	set splits [split $name "|"]

	# splits[0]= trafficItemName (00000-0000)
	# splits[1]= pgid
	# splits[2]= rx port label
	# splits[3]= flow label
	# splits[4]= tx port label

	# remove stream ids
	set tin [lindex $splits 0]
	set lastParen [expr [string last " (" $tin]-1]
	set tin [string range $tin 0 $lastParen]

	# if match against args, add to list
	set isTI [string equal $tin $trafficItemName]
	set isFlow [string equal -nocase [lindex $splits 3] $flowLabelStr]
	if { [expr $isTI && $isFlow] } {

	    # rx port filter
	    if { [string length $rxPortLabel] != 0 } {
		if { ! [string equal [lindex $splits 2] $rxPortLabel] } {
		    continue
		}
	    }

	    lappend objrefs $row
	}
    }

    # return list
    return $objrefs;
}

#####################################################################
# Helper: Reformat row name by removing "0" before card and ports
#####################################################################
proc ::ixTclNet::reformatRowName { rowName } {
    set splitString [split $rowName /]
    set hostName [lindex $splitString 0]
    set card     [string trimleft [lindex $splitString 1] "Card"]
    set port     [string trimleft [lindex $splitString 2] "Port"]
    # Trim "0" before numbers
    set card [expr $card*1]
    set port [expr $port*1]
    return "$hostName/$card/$port"
}

#######################################################################
# Helpler. To print out an array
#######################################################################
proc ::ixTclNet::PrintArray { StatValueArray} {
    upvar $StatValueArray statValueArray

    foreach name [lsort [array names statValueArray]] {
	set mystring [format "%s %s" $name $statValueArray($name) ]
	puts "$mystring"
    }
}

###############################################################################
#   Procedure Name: ::ixTclNet::ExportLearnedInfoToCsv
#   Description   : This procedure exports the learned info of the given
#                    protocol into a file in .csv format
#   Input         : vport    - virtual port
#                   proto    - protocol name
#                   filename - the file where to put the output in
#                               .csv format
#   output        : the learned info in .csv format
###############################################################################
proc ::ixTclNet::ExportLearnedInfoToCsv {vport proto filename} {
    set  _portDataList $vport
    foreach _portData $_portDataList {
	set errorMsg {}
	set isError [catch {::ixTclNet::[string toupper $proto]_export \
		$_portData $filename} errorMsg]

	if {$isError} {
	    expr {[regexp "invalid command name" $errorMsg] ? \
                 [puts "exportLearnedInfoToCsv is not supported for $proto"] : \
                 [puts "$errorMsg"]}
	    break
	}
    }
    return $isError
}

###############################################################################
#   Procedure Name: ::ixTclNet::BGP_export
#   Description   : fetches the BGP learned info and writes to a file
#                   in .csv format
#   Input         : vport    - virtual port
#                   filename - the file where to put the output in
#   output        : the learned info in .csv format
###############################################################################
proc ::ixTclNet::BGP_export {vport filename} {
    # The proposed CSV fields
    set peerType          "i"
    set networkAddrPrefix ""
    set nextHopAddress    ""
    set metric             0
    set localPref          0
    set weight             0
    set asPath            ""
    set originType        "i"

    set ixiaFileFormatVersion [ixNet exec getCurrentIxiaFileFormatTypeVersion]
    set index [string first "," $ixiaFileFormatVersion]
    set version_index [expr $index + 1]
    # If version moves to double digit we need change this logic
    set version [string index $ixiaFileFormatVersion $version_index]
    if [catch {set csvFileHadler [open $filename "w"]} errorMsg] {
	error $errorMsg
    }

    set filterList {ipv4Unicast}
    set bgp "$vport/protocols/bgp"
    set bgpNeighborList [ixNet getList $bgp neighborRange]
    puts $csvFileHadler "#Version:$version"

    foreach neighbour $bgpNeighborList {
	ixNet exec refreshLearnedInfo $neighbour
	set isComplete false
	while {$isComplete != true} {
	    set isComplete [ixNet getAttr $neighbour -isLearnedInfoRefreshed]
	    after 1000
	    if {$isComplete == true} {
		foreach fileType $filterList  {

		    set labelList [::ixNet getList \
			$neighbour/learnedInformation $fileType]

		    foreach item $labelList {
			set nextHop      [ixNet getAtt $item -nextHop]
			set prefixLength [ixNet getAtt $item -prefixLength]
			set ipPrefix     [ixNet getAtt $item -ipPrefix]

			# populate csv fields
			set peerType [string range \
			    [ixNet getAttr $neighbour -type] 0 0]

			set networkAddrPrefix "$ipPrefix/$prefixLength"
			set nextHopAddress    $nextHop

			set metric       [ixNet getAtt $item -multiExitDiscriminator]
			set localPref    [ixNet getAtt $item -localPreference]
			set asPath       [ixNet getAtt $item -asPath]
			set originType   [ixNet getAtt $item -originType]

			# format AS path to underscore seperated format
			# AS Path format in learned info <100 200 65538>{333,300,131074}<200>
			# should be exported as          <100_200_65538>{333_300_131074}<200>
			# into the ixia formatted csv file. We need to preserve all braces.

			set _asPath [string map { "> <" "><"
                                       "> (" ">("
                                       "> \[" ">\["
                                       "> \{" ">\{"
                                       ") <" ")<"
                                       ") (" ")("
                                       ") \[" ")\["
                                       ") \{" ")\{"
                                       "\} <" "\}<"
                                       "\} (" "\}("
                                       "\} \[" "\}\["
                                       "\} \{" "\}\{"
                                       "\] <" "\]<"
                                       "\] (" "\]("
                                       "\] \[" "\]\["
                                       "\] \{" "\]\{"
                                       " " "_"
                                       "," "_"} $asPath]

			set asPath $_asPath

			# format originType
			set _originType [string map -nocase {"IGP"        "i"  \
                                                             "EGP"        "e"  \
                                                             "Unknown"     ""  \
                                                             "Incomplete" "?"} \
			    $originType]
			set originType $_originType

			set tuple [join [list $peerType          \
			    $networkAddrPrefix \
			    $nextHopAddress    \
			    $metric            \
			    $localPref         \
			    $weight            \
			    $asPath            \
			    $originType] ","]
			puts $csvFileHadler $tuple
		    } ;# foreach item $labelList
		} ;# end foreach fileType $filterList
	    } ;# endif if {$isComplete == true}
	} ;# end while  {$isComplete != true}
    } ;# end neighbour $bgpNeighborList
    close $csvFileHadler
}

###############################################################################
#   Procedure Name: ::ixTclNet::getDeviceGroup
#   Description   : fetches the deviceGroup object
#   Input         : obj    - bgp peer object
#   output        : device group object
###############################################################################
proc ::ixTclNet::getDeviceGroup {obj} {
    set mlist ""
    set obj [split [string trim $obj] "/"]
    set root [split [lindex $obj 0] " "]
    lappend mlist $root
    set topology [split [lindex $obj 1] " "]
    lappend mlist $topology
    set deviceGroup [split [lindex $obj 2] " "]
    lappend mlist $deviceGroup
    set networkGroup [split [lindex $obj 3] " "]
    if { [string equal -length 12 $networkGroup "networkGroup"] != 0 } {
	lappend mlist $networkGroup
	set deviceGroup2 [split [lindex $obj 4] " "]
	if { [string equal -length 11 $deviceGroup2 "deviceGroup"] != 0 } {
	    lappend mlist $deviceGroup2
	}
    }
    regsub -all " " $mlist "/" mlist
    return $mlist
}

###############################################################################
#   Procedure Name: ::ixTclNet::getBgpProperty
#   Description   : fetches the attribute value
#   Input         : obj    - route property object
#				  : index  - item index within range
#				  : attribute - attribute name
#   output        : value of the attribute
###############################################################################	
proc ::ixTclNet::getBgpProperty {obj index attribute} {
    set routeObj $obj
    ixNet getAttribute $routeObj/item:$index -$attribute
}

###############################################################################
#   Procedure Name: ::ixTclNet::setBgpProperty
#   Description   : set the attribute value
#   Input         : obj    - route property object
#				  : index  - item index within range
#				  : attribute - attribute name
#                 : value - value to be set
#   output        : 
###############################################################################	
proc ::ixTclNet::setBgpProperty {obj index attribute value} {
    set routeObj $obj
    ixNet setAttribute $routeObj/item:$index -$attribute $value
}

###############################################################################
#   Procedure Name: ::ixTclNet::getAssignedRouteRangeList
#   Description   : fetches the list of route range behind a peer
#   Input         : obj    - route property object
#   output        : list of route range 
###############################################################################	
proc ::ixTclNet::getAssignedRouteRangeList {obj} {
    set ipRRList ""
    if { [ixNet exists $obj] == "false" } {
	error "ERROR: object $obj does not exist"
    }
    set obj [getDeviceGroup $obj]
    foreach networkGroup [ixNet getList $obj networkGroup] {
	if {[ixNet getList $networkGroup ipv4PrefixPools] != "" } {
	    set ipv4PrefixPools [ixNet getList $networkGroup ipv4PrefixPools]
	    foreach bgpIPRouteProperty [ixNet getList $ipv4PrefixPools bgpIPRouteProperty] {
		lappend ipRRList $bgpIPRouteProperty
	    }
	    foreach bgpV6IPRouteProperty [ixNet getList $ipv4PrefixPools bgpV6IPRouteProperty] {
		lappend ipRRList $bgpV6IPRouteProperty
	    }
	    foreach bgpL3VpnRouteProperty [ixNet getList $ipv4PrefixPools bgpL3VpnRouteProperty] {
		lappend ipRRList $bgpL3VpnRouteProperty
	    }
	    foreach bgpV6L3VpnRouteProperty [ixNet getList $ipv4PrefixPools bgpV6L3VpnRouteProperty] {
		lappend ipRRList $bgpV6L3VpnRouteProperty
	    }
	}
	if {[ixNet getList $networkGroup ipv6PrefixPools] != ""} {
	    set ipv6PrefixPools [ixNet getList $networkGroup ipv6PrefixPools]
	    foreach bgpIPRouteProperty [ixNet getList $ipv6PrefixPools bgpIPRouteProperty] {
		lappend ipRRList $bgpIPRouteProperty
	    }
	    foreach bgpV6IPRouteProperty [ixNet getList $ipv6PrefixPools bgpV6IPRouteProperty] {
		lappend ipRRList $bgpV6IPRouteProperty
	    }			
	    foreach bgpL3VpnRouteProperty [ixNet getList $ipv6PrefixPools bgpL3VpnRouteProperty] {
		lappend ipRRList $bgpL3VpnRouteProperty
	    }
	    foreach bgpV6L3VpnRouteProperty [ixNet getList $ipv6PrefixPools bgpV6L3VpnRouteProperty] {
		lappend ipRRList $bgpV6L3VpnRouteProperty
	    }			
	}
    }	
    return $ipRRList
}

##################################################################################
#   Procedure Name: ::ixTclNet::assignSimulatedTopologyRoutes
#   Description   : Changes the value of the attribute in Simulated Router
#   Input         : handle    - simulated router object
#				  : attribute - name of the attribute to changed
#				  : value - value
#                 : index - index of the simulated router in a range
#                 : bool - true/false only significant when we change entire range
#                          set it false for index specific change
#   output        :
##################################################################################
proc ::ixTclNet::assignSimulatedTopologyRoutes {handle attribute value step index bool} {
    set pseudoRouterType $handle
    if { $bool } {
	if { [string equal -length 14 $attribute "networkAddress"] != 0 } {
	    set attribute [ixNet getAttribute $pseudoRouterType -$attribute]
	    ixNet setMultiAttribute $attribute	-clearOverlays false \
		-pattern counter
	    ixNet commit
	    set attrCounter [ixNet add $attribute "counter"]
	    ixNet setMultiAttribute $attrCounter -step $step \
		-direction increment \
		-start $value	
	    ixNet commit
	    set attrCounter [lindex [ixNet remapIds $attrCounter] 0]

	    ixNet setMultiAttribute $attribute/nest:1 \
		-enabled false \
		-step 0.0.0.1

	    ixNet setMultiAttribute $attribute/nest:2 \
		-enabled false \
		-step 0.1.0.0
	    ixNet commit
	} else {
	    set attribute [ixNet getAttribute $pseudoRouterType -$attribute]
	    ixNet setMultiAttribute $attribute	-clearOverlays false \
		-pattern singleValue
	    ixNet commit
	    set attrSingleVal [ixNet add $attribute "singleValue"]
	    ixNet setMultiAttribute $attrSingleVal -value $value
	    ixNet commit
	    set attrSingleVal [lindex [ixNet remapIds $attrSingleVal] 0]

	    ixNet setMultiAttribute $attribute/nest:1 \
		-enabled false \
		-step true

	    ixNet setMultiAttribute $attribute/nest:2 \
		-enabled false \
		-step true
	    ixNet commit
	}			
    }
    if { $index > 0 } {
	set obj $handle
	ixNet setAttribute $obj/item:$index -$attribute $value
	ixNet commit
    }
}

#################################################################################################
#   Procedure Name: ::ixTclNet::createExternalLinks
#   Description   : Create External Links
#   Input         : networkTopology    - network topology object
#				  : otherNetworkTopology - other network topology handle
#				  : fromIndex - index from where link to be established
#                 : toIndex - index to which link to be established
#   output        : 
##################################################################################################
proc ::ixTclNet::createExternalLinks {networkTopology otherNetworkTopology fromIndex toIndex} {

    set externalLink [ixNet add $networkTopology "externalLink"]
    ixNet setMultiAttribute $externalLink \
	-fromNodeIndex $fromIndex \
	-toNodeIndex $toIndex
    ixNet commit
    set externalLink [lindex [ixNet remapIds $externalLink] 0]
    ixNet setMultiAttribute $externalLink -toNetworkTopology $otherNetworkTopology
    ixNet commit
}

#################################################################################################
#   Procedure Name: ::ixTclNet::createInternalLinks
#   Description   : Create External Links
#   Input         : networkTopology    - network topology object
#				  : fromIndex - index from where link to be established
#                 : toIndex - index to which link to be established
#   output        : 
##################################################################################################
proc ::ixTclNet::createInternalLinks {networkTopology fromIndex toIndex} {

    if { $fromIndex == $toIndex} {
	puts "fromIndex: $fromIndex and toIndex: $toIndex cannot be same"
	return
    }
    set netTopologyCustom [ixNet getList $networkTopology "netTopologyCustom"]
    if { [ixNet exists $netTopologyCustom] == "false" } {
	error "ERROR: object $netTopologyCustom does not exist"
    } else { 
	set fromList [ixNet getAttribute $netTopologyCustom/linkTable -fromNodeIndex]
	set fromList [linsert $fromList end $fromIndex]
	set toList [ixNet getAttribute $netTopologyCustom/linkTable -toNodeIndex ]
	set toList [linsert $toList end $toIndex]
	ixNet setMultiAttribute $netTopologyCustom/linkTable \
	    -fromNodeIndex $fromList \
	    -toNodeIndex $toList
	ixNet commit
    }
}


