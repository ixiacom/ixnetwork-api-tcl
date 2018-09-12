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


namespace eval ::ixNetworkInstall:: {
    #this file should be in $installDir/TclScripts/lib/IxTclNetwork,
    # and should add $installDir/TclScripts/lib to auto_path.
    set runningFromDir [file dirname [info script]]
    set TclScriptsLibDir [file normalize [file join $runningFromDir ..]]
    set baseInstallDir [file normalize [file join $TclScriptsLibDir .. ..]]
   
    ## Add the IxNProtocols dir also.
    ## Search using appinfo for the dependent IxNPRotocols component.    
    package require registry
         
    set installInfoFound false
    foreach {reg_path} [list "HKEY_LOCAL_MACHINE\\SOFTWARE\\Ixia Communications\\AppInfo\\InstallInfo" "HKEY_CURRENT_USER\\SOFTWARE\\Ixia Communications\\AppInfo\\InstallInfo"] {
        if { [ catch {registry get $reg_path "HOMEDIR"} r] == 0 } {
            set appinfo_path $r
            set installInfoFound true
            break
        }
    }
    # If the registy information was not found in either place, warn the user
    if { [string equal $installInfoFound "false"] } {        
        return -code error "Could not find AppInfo registry entry"
    }   
    set app_name "IxNetwork"     
    # Call appinfo to get the list of all dependencies:
    regsub -all "\\\\" $appinfo_path "/" appinfo_path      
    set appinfo_executable [file attributes "$appinfo_path/Appinfo.exe" -shortname]
    set appinfo_command "|\"$appinfo_executable\" --app-path \"$baseInstallDir\" --get-dependencies"    
    set appinfo_handle [open $appinfo_command r+ ]
    set appinfo_session {}
    
    while { [gets $appinfo_handle line] >= 0 } {
        # Keep track of the output to report in the error message below
        set appinfo_session "$appinfo_session $line\n"
        
        regsub -all "\\\\" $line "/" line
        regexp "^(.+):\ (.*)$" $line all app_name app_path       
        # If there is a dependency listed, add the path.
        
        if { [string first "IxNProtocols" $app_path ] != -1 } {
            # if the path has IxNProtocols add it       
            # Only add it if it's not already present:           
            if { -1 == [lsearch -exact $::auto_path $app_path ] } {
                lappend ::auto_path $app_path
                lappend ::auto_path [file join $app_path "TclScripts/lib/IxPublisher"]
                append ::env(PATH) [format ";%s" $app_path]                    
            }
        }
    }
    # If appinfo returned a non-zero result, this catch block will trigger.
    # In that case, show what we tried to do, and the resulting response.
    if { [catch {close $appinfo_handle} r] != 0} {
        return -code error "Appinfo error, \"$appinfo_command\" returned: $appinfo_session"
        }   
       
    lappend auto_path $TclScriptsLibDir
    
    # create this environment variable for supporting the sample scripts
    set env(IXNETWORK_SAMPLE_SCRIPT_DIR) $baseInstallDir/TclScripts/Sample
    
    catch {
        # Try to set things up for Wish.  
        if {[lsearch [package names] "Tk"] >= 0} {
        console show
        wm iconbitmap . "$baseInstallDir/wish.ico"
        #puts -nonewline "([file tail [pwd]]) %"
        }
    }

    console eval {
        .menubar.file add cascade -label "Save session" -underline 2 \
            -menu .menubar.file.sess
        menu .menubar.file.sess -tearoff 0
        .menubar.file.sess add command -label "Input only" \
            -underline 0 -command {saveSession 0}
        .menubar.file.sess add command -label "Input and Output" \
            -underline 10 -command {saveSession 1}
        proc saveSession {{all 1}} {
            set fTypes {{"TCL files" {.tcl}} {"All files" {*}}}
            set f [tk_getSaveFile -filetypes $fTypes -title "Save session"]
            if {$f == ""} {
                # User cancelled the dialog
                return
            }
            if [catch {open $f "w"} fh] {
                messageBox -icon error -message $fh -title \
                "Error while saving session"
                return
            }
            if {$all == 1} {
                puts $fh [.console get 0.0 end]
            } else {
                foreach {start end} [.console tag ranges stdin] {
                    puts -nonewline $fh [.console get $start $end]
                }
            }
            catch {close $fh}
        }
    }
}


