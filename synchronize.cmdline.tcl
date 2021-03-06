#!/bin/sh
# the next line restarts using tclsh \
    exec tclsh "$0" "$@"
#
#
# To do
#
# 1. publish muss project und lib directories kopieren
#
# 5. dir structure auf hagel und tabaluga vereinheitlichen
#    - *.html unter spb in Unterverziechnis
#    - fuer alle projects html dateien, z.B. rsse.html
#
# 6. html Dateien unter project/lib halbautomatisch generieren
# 7. Makefile fuer project dir wie bei lib (evtl. halbautomatisch generieren)
# 8. libcpm++.dxx, libfix++.dxx, libburst++.dxx (evtl auch automatisch)
# 9. scm/eps, scm/png Unterverzeichnisse
#
#

wm title . "Synchronize"
wm iconname . "Synchronize"
wm minsize . 1 1



proc Synchronize { sourceDir destDir} {
    global dirPermissions filePermissions
    
    if ![file exist $destDir] {
	file mkdir $destDir
    }
    if ![file exist $sourceDir] {
	file mkdir $sourceDir
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
    foreach file [glob -nocomplain *] {
	set source $file
	set dest [file join $destDir $source]
	
	set fileIndex [lsearch -exact $destFileList $source]
	if {$fileIndex != -1} {
	    set destFileList [lreplace $destFileList $fileIndex $fileIndex]
	}
	
	if [file isdirectory $source] {
	    puts "Synchronizing: [file join $pwd $sourceDir $source] <-> $dest"
	    flush stdout
	    Synchronize $source $dest
	} else {
	    if ![file exist $dest] {
		puts "Creating: $dest"
		file copy $source $dest
	    } elseif {[file mtime $source] > [file mtime $dest]} {
		puts "Updating: $dest"
		file copy -force $source $dest
	    } elseif {[file mtime $source] < [file mtime $dest]} {
		puts "Updating: $source"
		file copy -force $dest $source
	    }
	}
    }
    
    if [expr [llength $destFileList] > 0] {
	cd $destDir
	foreach file $destFileList {
	    puts "Creating: [file join $pwd $sourceDir $file]"
	    file copy $file [file join $sourceDir $file]
	}
    }
    
    cd $pwd
}



set sourceDir /Bordeaux/Incoming/cgi1
set destDir /Bordeaux/Incoming/cgi2
puts "Synchronizing $sourceDir -> $destDir"
flush stdout
Synchronize $sourceDir $destDir
puts "done."

