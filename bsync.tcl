#!/bin/sh
# the next line restarts using tclsh \
    exec wish "$0" ${1+"$@"}

#
# To do:
# / klicking Start two times in a row does not work because of a problem with the log stream not being found
# - show a table with sync items:
#   checkbutton(enabled) source dest link-dest options progressBar button(purgeOldBackups) 
#

package require tablelist

# file system with file ${backupDriveIdentifier} at its root will be used as backup disk
set backupDriveIdentifier "Buffalo.txt"


# syncItems
# ${backupDrive} will be expanded at runtime to the disk with the file ${backupDriveIdentifier} at its root
# ${date} will be expanded at runtime to the current date and time in format "%Y-%m-%d_%H-%M-%S"
dict set syncItems incrBackup_mail_old enabled 0
dict set syncItems incrBackup_mail_old source {d:/Mail/}
dict set syncItems incrBackup_mail_old dest {${backupDrive}/rsync/Mail_old/${date}}
dict set syncItems incrBackup_mail_old link-dest {${backupDrive}/rsync/Mail_old/latest}
dict set syncItems incrBackup_mail_old options {-a -u --progress --stats --delete}

dict set syncItems incrBackup_mail enabled 1
dict set syncItems incrBackup_mail source {d:/Mail/Mail.pst}
dict set syncItems incrBackup_mail dest {${backupDrive}/rsync/Mail/${date}/}
dict set syncItems incrBackup_mail link-dest {${backupDrive}/rsync/Mail/latest}
dict set syncItems incrBackup_mail options {-a -u --progress --stats --delete}

dict set syncItems fullBackup_repo_x2d enabled 1
dict set syncItems fullBackup_repo_x2d source {x:/Repositories/REPSVN_cpqpsk_2008-01-01/}
dict set syncItems fullBackup_repo_x2d dest {d:/Development/Repositories/REPSVN_cpqpsk_2008-01-01}
dict set syncItems fullBackup_repo_x2d options {-a -u --progress --stats --delete}

dict set syncItems incrBackup_repo_x enabled 1
dict set syncItems incrBackup_repo_x source {x:/Repositories/REPSVN_cpqpsk_2008-01-01/}
dict set syncItems incrBackup_repo_x dest {${backupDrive}/rsync/REPSVN_cpqpsk_2008-01-01/${date}}
dict set syncItems incrBackup_repo_x link-dest {${backupDrive}/rsync/REPSVN_cpqpsk_2008-01-01/latest}
dict set syncItems incrBackup_repo_x options {-a -u --progress --stats --delete}

dict set syncItems fullBackup_repo100GGUI_x2d enabled 1
dict set syncItems fullBackup_repo100GGUI_x2d source {x:/Repositories/REPSVN_CP-QPSKRX_GUI/}
dict set syncItems fullBackup_repo100GGUI_x2d dest {d:/Development/Repositories/REPSVN_CP-QPSKRX_GUI}
dict set syncItems fullBackup_repo100GGUI_x2d options {-a -u --progress --stats --delete}

dict set syncItems incrBackup_repo100GGUI_x enabled 1
dict set syncItems incrBackup_repo100GGUI_x source {x:/Repositories/REPSVN_CP-QPSKRX_GUI/}
dict set syncItems incrBackup_repo100GGUI_x dest {${backupDrive}/rsync/REPSVN_CP-QPSKRX_GUI/${date}}
dict set syncItems incrBackup_repo100GGUI_x link-dest {${backupDrive}/rsync/REPSVN_CP-QPSKRX_GUI/latest}
dict set syncItems incrBackup_repo100GGUI_x options {-a -u --progress --stats --delete}

dict set syncItems incrBackup_d enabled 1
dict set syncItems incrBackup_d source {d:/}
dict set syncItems incrBackup_d dest {${backupDrive}/rsync/d/${date}}
dict set syncItems incrBackup_d link-dest {${backupDrive}/rsync/d/latest}
dict set syncItems incrBackup_d options {-a -u --progress --stats --delete --exclude "Copernic/" --exclude "RECYCLER/" --exclude "Mail/" --exclude "PROT_INS.SYS" --delete-excluded}



# set some default values
set logToPane true
set logToFile true

set scriptDir "[file dirname [info script]]"
set logFile [file join $scriptDir bsync.log]


#
# log pane handling
#

set verbosityLevel Info
array set outputSeverity [list Error 0 Warning 1 Info 2 Pipe 3 Debug 4]
array set outputLabel [list Error "Error: " Warning "Warning: " Info "" Pipe "" Debug "Debug: "]
array set outputColor [list Error fgRed Warning fgOrange Info {} Pipe fgBrown Debug fgBlue]

# true -> force output to stdout instead of log pane
set forceStdout false

proc putsLog {args} {
    global outputSeverity outputLabel outputColor
    global log verbosityLevel forceStdout
    global logToPane 
    global logToFile logStream

    set option ""
    if {[llength $args] > 1} {
	if {[lindex $args 0] == "-nonewline"} {
	    set option "-nonewline"
	    set args [lreplace $args 0 0]
	}
    }

    if {[llength $args] == 1} {
	set type Info
    } elseif {[llength $args] == 2} {
	set type [lindex $args 1]
    } else {
	putsLog "putsLog: wrong number of arguments ([llength $args]). Should be 1 or 2." Error
    }

    set string [lindex $args 0]

    if {$outputSeverity($type) <= $outputSeverity($verbosityLevel)} {
	if {[info exists log] && $logToPane == "true"} {
	    if {$option == "-nonewline"} {
		$log insert end "$outputLabel($type)$string" $outputColor($type)
	    } else {
		$log insert end "$outputLabel($type)$string\n" $outputColor($type)
	    }
	    $log see end
	}
	if {$logToFile == "true" && [info exists logStream]} {
	    if {$option == "-nonewline"} {
		puts -nonewline $logStream "$outputLabel($type)$string"
	    } else {
		puts $logStream "$outputLabel($type)$string"
	    }
	}
    }
}


# 
# platform dependent settings: modifier keys, preference files location, paths to helper applications
#

switch -exact [tk windowingsystem] {

    "aqua" {
	# Mac OS X systems
	# Key for menu shortcuts
	set modifier Command

	# Preferences files location (user independent)
	set pmAppPrefs [file join $scriptDir prefsDefaults.tcl]
	# Preferences files location (user specific)
	set pmUserPrefs [file join $env(HOME) .bsync]

	# directory where helper applications (rsync, ln, rm) can be found
	set path "[file join /usr local bin]:[file join /bin]:[file join /usr bin]:[file join /sbin]:[file join /usr sbin]"
	set pathSeparator ":"
    }

    "win32" {
	# windows systems (including cygwin)
	# Key for menu shortcuts
	set modifier Control

	# Preferences files location (user independent)
	set pmAppPrefs [file join $scriptDir prefsDefaults.tcl]
	# Preferences files location (user specific)
	set pmUserPrefs [file join $env(HOME) .bsync]

	# directory where helper applications (rsync, ln, rm) can be found
	set path "[file join c:/ cygwin bin]"
	set pathSeparator ";"
    }

    default {
	# various flavours of unix
	# Key for menu shortcuts
	set modifier Meta

	# Preferences files location (user independent)
	set pmAppPrefs [file join $scriptDir prefsDefaults.tcl]
	# Preferences files location (user specific)
	set pmUserPrefs [file join $env(HOME) .bsync]

	# directory where helper applications (rsync, ln, rm) can be found
	set path "[file join /usr local bin]:[file join /bin]:[file join /usr bin]:[file join /sbin]:[file join /usr sbin]"
	set pathSeparator ":"
    }
}


#
# Procedures to spawn an external process asynchronously and process returned output as it becomes available
#


# get output from spawned process
proc pipeGetOutput {} {
    global mstream
    global guiItems

    if [info exists mstream] {
	if ![eof $mstream] {
	    if {[gets $mstream line] >= 0} {
		# process output will usually end up here
		if [regexp {xfer#([0-9]*), to-check=([0-9]*)/([0-9]*)} $line match copied toCheck total] {
		    # handle lines of the form
		    #          437 100%    2.05kB/s    0:00:00 (xfer#137, to-check=1056/97070)
		    set guiItems(itemsCopied) $copied
		    set guiItems(itemsToCheck) $toCheck
		    set guiItems(itemsTotal) $total
		    putsLog "$line" Debug
		    # optionally update one of the table cells
		    #$tbl cellconfigure $nr,4 -text "0 %"
		} elseif [regexp {[[:digit:]]+.*[[:digit:]]+:[[:digit:]][[:digit:]]:[[:digit:]][[:digit:]]} $line] {
		    # suppress lines of the form
		    #          437 100%    2.05kB/s    0:00:00
		    putsLog "$line" Debug
		} else {
		    # output everything else
		    putsLog "$line" Pipe
		}
	    } else {
		# it seems that just before eof one line ends up here
		# just read it to empty the channel
  		putsLog "[read $mstream]" Debug
	    }
	} else {
	    putsLog "pipeGetOutput: detected eof! Closing..." Warning
	    pipeStop
	}
    } else {
	putsLog "pipeGetOutput: variable mstream is not set!" Error
    }
}

# launch external process in read write mode
proc pipeStart {cmd} {
    global mstream guiItems 
    global tbl activeSyncItemNr

    if ![info exists mstream] {
	putsLog "starting $cmd. Please be patient!" Warning
	if [catch {open "|$cmd" r+} mstream] {
	    putsLog "pipeStart: $mstream" Error
	} else {
	    fconfigure $mstream -buffering line
	    fconfigure $mstream -blocking 0
	    fileevent $mstream readable pipeGetOutput
	    $tbl rowconfigure $activeSyncItemNr -fg orange
	}
    } else {
	putsLog "pipeStart: process is already running!" Error
    }
}

# launch external process for writing only
proc pipeStartWriteOnly {cmd} {
    global mstream

    if ![info exists mstream] {
	putsLog "starting $cmd. Please be patient!" Warning
	if [catch {open "|$cmd" w} mstream] {
	    putsLog "pipeStartWriteOnly: $mstream" Error
	} else {
	    fconfigure $mstream -buffering line
	}
    } else {
	putsLog "pipeStartWriteOnly: process is already running!" Error
    }
}

# send a command to external process
proc pipeSend { arg } {
    global mstream

    #    pipeStart
    
    if [info exists mstream] {
	puts $mstream $arg
	putsLog "pipeSend: $arg"
    } else {
	putsLog "pipeSend: process is not running!" Error
    }
}

# close the pipe to external process
proc pipeStop {} {
    global mstream state
    global tbl activeSyncItemNr

    if [info exists mstream] {
	close $mstream
	unset mstream
	putsLog "process terminated!" Warning
	set state syncDone
	$tbl rowconfigure $activeSyncItemNr -fg green
    } else {
	putsLog "pipeStop: process is not running!" Error
    }
}


#
# File system handling
#

proc currentDateAndTime {} {
    return [clock format [clock seconds] -format "%Y-%m-%d_%H-%M-%S"]
}


# returns the disk space available on drive which holds 'file'. 'unit' can
# be one of kB, MB or GB. Default is kB.
proc availableDiskSpace {file unit} {
    global commands

    switch $::tcl_platform(platform) {
	windows {
	    cd [file dirname $file]
	    set res [eval exec [auto_execok dir]]
	    set var [expr [llength $res] -3]
	    set df [string map {. {}} [lindex $res $var]]
	    set df [expr $df / 1024]
	}
	macintosh {
	    return 0
	}
	default {
	    # get file system usage of drive on which 'file' lives
	    if [catch {exec $commands(df) [win2Cygwin $file]} df] {
		putsLog "while calling df: $df" Error
		return 0
	    }

	    # split df output into lines
	    set df [split $df \n]

	    # number of lines must be 2. Otherwise there is something wrong
	    if {[llength $df] != 2} {
		puts "output of 'df' does not have exactly two lines. Output was: $df" Error
		return 0
	    }

	    # Now df is of the form:
	    #Filesystem 1K-blocks Used Available Use% Mounted on
	    #F: 244196000 175863688 68332312 73% /cygdrive/f

	    # get second line, substitute runs of spaces by a single space and split
	    set df [split [regsub -all {[ ]+} [lindex $df 1] { }]]

	    # df info should have exactly 6 columns. Otherwise there is something wrong
	    if {[llength $df] != 6} {
		puts "output of 'df' does not have exactly six columns. Output was: $df" Error
		return 0
	    } else {
		set df [lindex $df 3]
	    }
	}
    }

    switch -exact $unit {
	MB {set df [expr $df / 1024]}
	GB {set df [expr $df / 1024 / 1024]}
	default {}
    }

    return $df
}


# takes a Windows path (e.g. C:/foo/bar) and returns the cygwin equivalent (/cygdrive/c/foo/bar)
# NOTE: a trailing / is preserved
proc win2Cygwin {path} {
    if {[string index [string trim $path] end] == "/"} {
	set trailingSlash "/"
    } else {
	set trailingSlash ""
    }
    set dirs [file split $path]

    if [regexp {([a-z]):/} [string tolower [lindex $dirs 0]] match drive] {
	set dirs [lreplace $dirs 0 0 / cygdrive $drive]
    }
    return [eval file join $dirs]$trailingSlash
}


# searches all connected drives for one with the file "identifier" at root file system level 
# and returns the path to this file system's root
proc backupDrive {identifier} {

    set drive "not found"
    putsLog -nonewline "searching for backup drive... "
    update idletasks
    foreach aDrive [file volumes] {
	if [file exists [file join $aDrive $identifier]] {
	    set drive $aDrive
	    break
	}
    }
    if {$drive == "not found"} {
	putsLog ""
	putsLog "couldn't find backup drive. Must contain file \"$identifier\" at file system root level." Error
    } else {
	putsLog $drive
    }
    return $drive
}


# sets the names of some helper executables. They are assumed to live in one of the directories given by pathList
# returns true if all commands have been found on path, false otherwise
proc findCommands {commandNames pathList pathSeparator} {
    global commands

    catch {unset commands}

    set found true
    foreach name $commandNames {
	putsLog -nonewline "looking for $name... "
	foreach path [split $pathList $pathSeparator] {
	    if {[file exists [file join $path $name]] || [file exists [file join $path $name].exe]} {
		set commands($name) [file join $path $name]
		putsLog "$commands($name)"
		break
	    }
	}
	if ![info exists commands($name)] {
	    putsLog ""
	    putsLog "not found." Error
	    set found false
	}
    }

    if {$found == true} {
	if [catch {exec $commands(rsync) --help} rsyncOutput] {
	    putsLog "error calling rsync: $rsyncOutput" Error
	} else {
	    # output rsync version
	    putsLog "[lindex [split $rsyncOutput \n] 0]"
	}
    }

    return $found
}


#
# Main backup procedure (called when Start button is pressed)
#

proc mainDialog_buttonStartSync {} {
    global state activeSyncItemNr
    global logStream logFile
    global syncItems commands guiItems tbl progressBar
    global backupDriveIdentifier

    set guiItems(backupDrive) [backupDrive $backupDriveIdentifier]
    set backupDrive $guiItems(backupDrive)

    setEnabledStateInDictFromArray

    if {$backupDrive != "not found"} {
	if [catch {open $logFile w} logStream] {
	    putsLog "$logStream" Error
	} else {
	    $progressBar start
	    dict for {name info} $syncItems {
		if [dict get $syncItems $name enabled] {
		    set activeSyncItemNr [lsearch -exact [dict keys $syncItems] $name]
		    set guiItem(memoryAvailable) [availableDiskSpace $guiItems(backupDrive) GB]
		    set date [currentDateAndTime]
		    putsLog "${date} Running sync item $name"
		    set state "Running sync item $name"
		    dict with info {
			set startTime [clock seconds]
			if [dict exists $syncItems $name link-dest] {
			    set cmd "$commands(nice) $commands(rsync) $options --link-dest=[win2Cygwin [subst ${link-dest}]] [win2Cygwin [subst $source]] [win2Cygwin [subst $dest]]"
			    pipeStart $cmd
			    vwait state
			    if [file isdirectory [subst $dest]] {
				set cmd "$commands(rm) -f [win2Cygwin [subst ${link-dest}]]"
				if [catch {eval exec $cmd} error] {
				    putsLog "$cmd returned $error" Error
				    $tbl rowconfigure $activeSyncItemNr -fg red
				} else {
				    putsLog "$cmd"
				}
				set cmd "$commands(ln) -s [win2Cygwin [subst $dest]] [win2Cygwin [subst ${link-dest}]]"
				if [catch {eval exec $cmd} error] {
				    putsLog "$cmd returned $error" Error
				    $tbl rowconfigure $activeSyncItemNr -fg red
				} else {
				    putsLog "$cmd"
				}
			    } else {
				putsLog "something went wrong during backup. Dir [subst $dest] does not exist. Link [subst ${link-dest}] unchanged." Error
				$tbl rowconfigure $activeSyncItemNr -fg red
			    }
			} else {
			    set cmd "$commands(nice) $commands(rsync) $options [win2Cygwin [subst $source]] [win2Cygwin [subst $dest]]"
			    pipeStart $cmd
			    vwait state
			}
			set endTime [clock seconds]
			putsLog "Elapsed time: [clock format [expr $endTime - $startTime] -format {%H:%M:%S} -timezone :UTC]"
		    }
		}
	    }

	    set state "Done."
	    set guiItem(memoryAvailable) [availableDiskSpace $guiItems(backupDrive) GB]
	    close $logStream
	    $progressBar stop
	}
    }
}




proc mainDialog_buttonQuit {} {
    exit
}


#
# GUI
#

#------------------------------------------------------------------------------
# createCheckButton
#
# Creates a checkbutton widget w to be embedded into the specified cell of the
# tablelist widget tbl.
#------------------------------------------------------------------------------
proc createCheckButton {tbl row col w} {
    set key [$tbl getkeys $row]
    checkbutton $w -variable enabledState($key)
    #    if [$tbl cellcget $row,enabled -text] {
    #	puts "row = $row, key = $key, $w selected"
    #	#$w select
    #    } else {
    #	puts "row = $row, key = $key, $w deselected"
    #	#$w deselect
    #    }
}

# used by tablelist when formatting the text in a checkbutton cell
proc emptyStr val { return "" }

# main dialog
proc mainDialogOpen {} {
    global log guiItems state 
    global syncItemsList
    global logToPane logToFile
    global tbl progressBar

    # top level window
    set top {}

    # put window in upper left corner and set window name
    option add *highlightThickness 0   
    wm geometry . +0+0
    wm title . "bsync"
    wm iconname . "bsync"
    wm minsize . 1 1

    
    # top frame for control elements
    frame $top.ft -borderwidth 1;# -bg yellow
    pack $top.ft -side top -fill both
    
    # paned window with two vertically stacked frames
    ttk::panedwindow $top.pw -orient vertical
    pack $top.pw -expand yes -fill both -pady 2 -padx 2m
    
    # middle frame for syncItem list
    frame $top.pw.fm -borderwidth 1;# -bg yellow
    pack $top.pw.fm -side top -fill both
    
    # bottom frame for scrolling info pane
    frame $top.pw.fb -borderwidth 1;# -bg red
    pack $top.pw.fb -side top -fill both -expand true

    # add frames to the paned window
    $top.pw add $top.pw.fm
    $top.pw add $top.pw.fb

    # frame for logToPane and logToFile buttons
    frame $top.ft.f1 -borderwidth 1;# -bg green
    pack $top.ft.f1 -side top -fill both -expand true -anchor n
    
    # frame for items entries
    frame $top.ft.f2 -borderwidth 1;# -bg blue
    pack $top.ft.f2 -side top -fill x -anchor n

    # frame for state entry and Start/Quit buttons
    frame $top.ft.f3 -borderwidth 1;# -bg brown
    pack $top.ft.f3 -side top -fill x -anchor n

    # backup drive entry and logToPane and logToFile buttons
    label $top.ft.f1.labelDrive -text "Backup drive:"
    entry $top.ft.f1.entryDrive -width 10 -textvariable guiItems(backupDrive)
    label $top.ft.f1.memoryAvailable -text "?" -textvariable guiItems(memoryAvailable)
    label $top.ft.f1.labelAvailable -text "GB available"
    pack $top.ft.f1.labelDrive $top.ft.f1.entryDrive $top.ft.f1.memoryAvailable $top.ft.f1.labelAvailable -side left -anchor nw -padx 5 -pady 5

    label $top.ft.f2.labelStatus -text "State:"
    label $top.ft.f2.status -text "idle" -textvariable state
    pack $top.ft.f2.labelStatus $top.ft.f2.status -side left -anchor nw -padx 5 -pady 5
    set progressBar [ttk::progressbar $top.ft.f2.pb -orient horizontal -length 300 -mode indeterminate]
    pack $progressBar -side left -anchor nw -padx 10 -pady 5 -fill x
    checkbutton $top.ft.f2.logToPane -text "Log output to pane" -offvalue false -onvalue true -variable logToPane  
    checkbutton $top.ft.f2.logToFile -text "Log output to file" -offvalue false -onvalue true -variable logToFile  
    pack $top.ft.f2.logToPane $top.ft.f2.logToFile -side right -anchor nw -padx 5 -pady 5

    label $top.ft.f3.labelCopied -text "Items copied:"
    entry $top.ft.f3.entryCopied -width 10 -textvariable guiItems(itemsCopied)
    pack $top.ft.f3.labelCopied $top.ft.f3.entryCopied -side left -anchor nw -padx 5 -pady 5

    label $top.ft.f3.labelCheck -text "Items to check:"
    entry $top.ft.f3.entryCheck -width 10 -textvariable guiItems(itemsToCheck)
    pack $top.ft.f3.labelCheck $top.ft.f3.entryCheck -side left -anchor nw -padx 5 -pady 5

    label $top.ft.f3.labelTotal -text "Total:"
    entry $top.ft.f3.entryTotal -width 10 -textvariable guiItems(itemsTotal)
    pack $top.ft.f3.labelTotal $top.ft.f3.entryTotal -side left -anchor nw -padx 5 -pady 5

    button $top.ft.f3.startSyncButton -text "Start" -command mainDialog_buttonStartSync
    button $top.ft.f3.quitButton -text "Quit" -command mainDialog_buttonQuit
    pack $top.ft.f3.quitButton $top.ft.f3.startSyncButton -side right -anchor sw -padx 5 -pady 5
    

    # middle frame for sync items list
    set tbl $top.pw.fm.tbl
    set hsb $top.pw.fm.hsb
    set vsb $top.pw.fm.vsb

    set columns [list 0 On 20 "Name" 20 Source 20 Destination 20 Link-Dest 15 Options]

    tablelist::tablelist $tbl -columns $columns \
	-labelcommand tablelist::sortByColumn \
	-xscrollcommand [list $hsb set] -yscrollcommand [list $vsb set] \
	-height 10 -width 0 \
	-listvariable syncItemsList

    #    -stretch all -stripeheight 1 \
	#	-labelfont {-family lucida-grande -size 10} \
	#	-font {-family lucida-grande -size 10} \
	#	-setgrid yes 
    $tbl columnconfigure 0 -name enabled -formatcommand emptyStr
    $tbl columnconfigure 1 -name name

    # Create embedded checkbuttons in the column no. 0
    set rowCount [llength $syncItemsList]
    for {set row 0} {$row < $rowCount} {incr row} {
	$tbl cellconfigure $row,enabled -window createCheckButton
    }

    scrollbar $vsb -orient vertical   -command [list $tbl yview]
    scrollbar $hsb -orient horizontal -command [list $tbl xview]
    
    grid $tbl -row 0 -column 0 -sticky news
    grid $vsb -row 0 -column 1 -sticky ns
    grid $hsb -row 1 -column 0 -sticky ew
    grid rowconfigure    $top.pw.fm 0 -weight 1
    grid columnconfigure $top.pw.fm 0 -weight 1


    # bottom frame for scrolling info pane
    set log [text $top.pw.fb.log -width 100 -height 20 \
		 -borderwidth 2 -relief raised -wrap word -setgrid true \
		 -yscrollcommand [list $top.pw.fb.scroll set]]
    $log tag configure fgRed -foreground red
    $log tag configure fgOrange -foreground orange
    $log tag configure fgBlue -foreground blue
    $log tag configure fgGreen -foreground green
    $log tag configure fgBrown -foreground brown
    
    scrollbar $top.pw.fb.scroll -command [list $top.pw.fb.log yview]
    pack $top.pw.fb.scroll -side right -fill y
    pack $top.pw.fb.log -side left -fill both -expand true
} 


# This procedure retrieves sync items from the main sync items dictionary
# and fills them in the global variable syncItemsList in nested list form.
# This list is linked to the tablelist widget that displays the sync items 
# in the GUI, i.e., polupating this list at the same time polutates the 
# table in the GUI.
proc setSyncItemsListFromDict {syncItems} {
    global syncItemsList

    set syncItemsList {}
    dict for {name info} $syncItems {
	putsLog "Registering sync item $name"
	dict with info {
	    if [dict exists $syncItems $name link-dest] {
		set item [list $enabled $name $source $dest ${link-dest} $options]
	    } else {
		set item [list $enabled $name $source $dest {} $options]
	    }
	    lappend syncItemsList $item
	}
    }
}


# transfer the value of the enabled column into the global array enabledState
proc setEnabledStateArrayFromGUI {} {
    global tbl enabledState

    set rowCount [$tbl size]
    for {set row 0} {$row < $rowCount} {incr row} {
	set key [$tbl getkeys $row]
	set enabledState($key) [$tbl cellcget $row,enabled -text]
    }
}


# getEnabledStateFromGUI reads the enabled state of each sync item from the 
# global variable enabledState (which is linked to the tablelist widget that
# displays the sync items in the GUI) and updates the state of each sync item
# in the main dictionary syncItems (which is used for actual syncing).
proc setEnabledStateInDictFromArray {} {
    global syncItems enabledState tbl

    # array enabledState holds the state of the checkbuttons in column 0 of the table
    # dict syncItems contains info of what is actually synchronized
    set rowCount [$tbl size]
    for {set row 0} {$row < $rowCount} {incr row} {
	set key [$tbl getkeys $row]
	dict set syncItems [$tbl cellcget $row,name -text] enabled $enabledState($key)
    }
    putsLog "dictionary syncItems = [dict get $syncItems]" Debug
}


setSyncItemsListFromDict $syncItems
mainDialogOpen
tkwait visibility $log
setEnabledStateArrayFromGUI

putsLog "tcl_version = $tcl_version"
putsLog "tk_version = $tk_version"

set helperCommands [list rsync nice rm ln df]
findCommands $helperCommands $path $pathSeparator

update
set guiItems(backupDrive) [backupDrive $backupDriveIdentifier]
if {$guiItems(backupDrive) != "not found"} {
    set guiItems(memoryAvailable) [availableDiskSpace $guiItems(backupDrive) GB]
}

