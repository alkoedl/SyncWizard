#!/bin/sh
# the next line restarts using tclsh \
    exec wish "$0" "$@"

#
#
# A GUI to compare two folders
#
#

wm title . "Compare"
wm iconname . "Compare"
wm minsize . 1 1


proc SetButtonState {transferIsGoingOn} {
    if {$transferIsGoingOn == "true"} {
	.top1.open1 config -state disabled
	.top2.open2 config -state disabled
	.bot.quit config -state disabled
	.bot.startStop config -text Cancel -command Cancel -state normal
	.bot.cancelAll config -state normal
    } else {
	.top1.open1 config -state normal
	.top2.open2 config -state normal
	.bot.quit config -state normal
	.bot.startStop config -text Start -command StartSync -state normal
	.bot.cancelAll config -state disabled
    }
}

# procedure for adding a horizontal bar into the main window
set sepId 1
proc sep {} {
    global sepId
    frame .sep$sepId -height 2 -bd 1 -relief sunken
    pack .sep$sepId -side top -padx 2m -pady 2m -fill x
    incr sepId
}

proc CreateWindow {} {
    global folder1 folder2 currFile fieldWidth
    global openButton cancelAllButton startStopButton quitButton infoButton

    # Create a frame for download spec filename
    frame .top1 -borderwidth 10 
    pack .top1 -side top -fill x -expand false 

    label .top1.l1 -text "Folder1 = "
    entry .top1.folder1 -width $fieldWidth -relief sunken -textvariable folder1
    set open1Button [button .top1.open1 -text Browse... -command [list Browse folder1]]
    pack .top1.l1 -side left -padx 1m
    pack .top1.folder1 -side left -fill x -expand true -padx 1m
    pack .top1.open1 -side right -padx 1m -pady 1m
    sep
    
    frame .top2 -borderwidth 10 
    pack .top2 -side top -fill x -expand false 

    label .top2.l2 -text "Folder2 = "
    entry .top2.folder2 -width $fieldWidth -relief sunken -textvariable folder2
    set open2Button [button .top2.open2 -text Browse... -command [list Browse folder2]]
    pack .top2.l2 -side left -padx 1m
    pack .top2.folder2 -side left -fill x -expand true -padx 1m
    pack .top2.open2 -side right -padx 1m -pady 1m
    sep
    
    # Create a frame, label for download progress and cancel/cancel all buttons 
    frame .top -borderwidth 10 
    pack .top -side top -fill x -expand false 
    
    label .top.l -text Examining
    entry .top.currFile -width $fieldWidth -relief sunken -textvariable currFile
    .top.currFile config -state disabled
    pack .top.l -side left -padx 1m
    pack .top.currFile -side left -fill x -expand true -padx 1m

    sep
    frame .bot -borderwidth 10 
    pack .bot -side top -fill x -expand false 
    
    set cancelAllButton [button .bot.cancelAll -text "Cancel all" -command CancelAll]
    set startStopButton [button .bot.startStop -text Cancel -command Cancel]
    set quitButton [button .bot.quit -text Quit -command Quit]
    pack .bot.quit .bot.startStop .bot.cancelAll -side right -padx 1m -pady 1m
    
    SetButtonState false
    set folder1 {}
    set folder2 {}
    set currFile {}
}


# browse for files from the disk
proc Browse {folderName} {
    upvar #0 $folderName folder

    set newDir [tk_chooseDirectory -initialdir $folder -mustexist true -title "Choose a folder to synchronize"]
    if { $newDir != {} } {
	set folder $newDir
    }
}


proc Quit {} {
    destroy .
}

proc Cancel {} {
    global quit
    
    SetButtonState false
    set quit true
}





proc Synchronize {sourceDir destDir} {
    global currFile ostream quit exclusionList
    
    if ![file exist $destDir] {
	puts $ostream "B: missing dir $destDir"
	return
    }
    if ![file exist $sourceDir] {
	puts $ostream "A: missing dir $sourceDir"
	return
    }
    
    set pwd [pwd]
    if [catch {cd $destDir} err] {
	puts stderr $err
	return
    }
    set destFileList [glob -nocomplain *]
    cd $pwd
    
    set pwd [pwd]
    if [catch {cd $sourceDir} err] {
	puts stderr $err
	return
    }
    
    # 	puts "sourceFileList = [glob -nocomplain *]"
    # 	puts "destFileList = $destFileList"

    foreach file [glob -nocomplain *] {
	
	set source [file join $sourceDir $file]
	set dest [file join $destDir $file]
	#puts $ostream "Comparing: $source and $dest"
	
	set fileIndex [lsearch -exact $destFileList $file]
	if {$fileIndex != -1} {
	    set destFileList [lreplace $destFileList $fileIndex $fileIndex]
	}
	
	set currFile $source
	update
	if {$quit == "true"} {
	    break;
	}
	
	if [file isdirectory $file] {
	    #puts $ostream "Comparing dirs: $source <-> $dest"
	    #flush $ostream
	    Synchronize $source $dest
	} else {
	    set fileType [file attributes $source -type]
	    if {[lsearch $exclusionList $fileType] == -1} {
		if ![file exist $dest] {
		    puts $ostream "B: missing $dest"
		    #file copy $source $dest
		} elseif {[file mtime $source] > [file mtime $dest]} {
		    puts $ostream "A newer than B: $dest"
		    #file copy -force $source $dest
		} elseif {[file mtime $source] < [file mtime $dest]} {
		    puts $ostream "B newer than A: $source"
		    #file copy -force $dest $source
		}
	    } else {
		puts $ostream "Excluded: $source"
	    }
	}
    }
    
    if {[expr [llength $destFileList] > 0] && $quit == "false"} {
	cd $destDir
	foreach file $destFileList {
	    if [file isdirectory $file] {
		set currFile [file join $pwd $sourceDir $file]
		puts $ostream "A: missing dir $currFile"
	    } else {
		set fileType [file attributes $file -type]
		if {[lsearch $exclusionList $fileType] == -1} {
		    set currFile [file join $pwd $sourceDir $file]
		    puts $ostream "A: missing $currFile"
		    update
		    #file copy $file [file join $sourceDir $file]
		} else {
		    puts $ostream "Excluded: [file join $destDir $file]"
		}
	    }
	}
    }
    
    cd $pwd
}


proc StartSync {} {
    global folder1 folder2 currFile logFile ostream quit
    
    # open log file
    if [catch {open $logFile w} ostream] {
	puts stderr "$ostream\n"
    } else {	
	puts $ostream "Comparing A: $folder1 <-> B: $folder2"
	SetButtonState true
	set quit false
	Synchronize $folder1 $folder2
	SetButtonState false
	set currFile "Done"
	puts $ostream "Done"
	close $ostream
    }
}


#
# Build user interface
#
set fieldWidth 40
CreateWindow

$startStopButton config -text Start -command StartSync

#set folder1 [file join /Users admin Tmp]
#set folder2 [file join /Users admin Tmp1]

set folder1 [file join /Users Admin Pictures {iPhoto Library}]
set folder2 [file join /Volumes Porto Backups.backupdb Greece Latest Sami Users Admin Pictures {iPhoto Library}]

set exclusionList [list ]

set logFile [file join [file dirname [info script]] compare.log]


