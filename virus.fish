#!/usr/bin/fish
# set fish_trace 1

#############################################
# virus.fish
#
# Do you use Linux? 
# Do you make music? 
# Do you use the DSP56300Emu VST to emulate an Access Virus C but want its factory presets to integrate with your Bitwig Studio preset browser?
# 
# This is a fish shell script which automates the mouse and key presses needed to create a .bwpreset for each factory preset.
#
#
# Prerequisites:
# - an X11 environment
# - sudo apt install tesseract-ocr
# - sudo apt install xdotool
# - Bitwig Studio (Tested on 4.3)
# - DSP56300Emu (Tested on 1.2.20, VST2, Hoverland skin, Virus C rom)
# also, 
# - You have no Bitwig presets for DSP56300Emu already (because, we do not handle the dialog where Bitwig asks if you want to replace an existing preset)
# - In Bitwig, the shortcut for 'Save to Library' must be set to Numpad *
# - The default shortcuts must be set for 
#		focus/toggle device panel (d)
#		focus toggle/arranger window (o)
# 		focus track header (t)
#		rename track header (Ctrl-r)
# - You must start from a Bitwig project with no tracks open.
#
#
# Remember to like and subscribe
#############################################

# Usage / Input validation
if test (count $argv) -eq 0
	set argv[1] 1
	set argv[2] 1
	set argv[3] 1
	set argv[4] 1
	set argv[5] 1
	set argv[6] 1
else if test (count $argv) -eq 6
	:
else
	echo " Usage:"
	echo "	./virus.fish"
	echo " 		This asks the program to process banks C through H entirely."
	echo ""
	echo " 	./virus.fish 0 0 75 1 1 1"
	echo " 		This asks the program to process (i.e. if you want to resume your progress):"
	echo "			Bank C not at all"
	echo "			Bank D not at all"
	echo "			Bank E 75-128"
	echo "			Bank F 1-128"
	echo "			Bank G 1-128"
	echo "			Bank H 1-128"

	exit
end


#
# Magic numbers (All generated from a 4k display with DSP56300Emu scaled to 150%)
#
set EMU_BROWSERXY 290 270 # XY coordinate for the 'factory preset browser' UI target (i.e. where clicking opens the Bank A-E dropdown)
set EMU_TITLEXY 750 95 # the program title UI target (i.e. where double clicking allows you to edit the title)
set EMU_SETTINGSXY 1405 180 # the 'Arp | Settings' tab UI target (i.e. where clicking takes you to the page displaying the Category 1 and Category 2 dropdowns)

# bounding box coordinates for the Category 1 dropdown (for optical character recognition purposes): 
# top left X, top left Y, bottom right X, bottom right Y
set EMU_CAT1XY 1705 810 1830 840
set EMU_CAT2XY 1862 810 1977 840 # bounding box for Category 2



########
# CONSTANTS / MACROS
########
set TRACK_TITLE "_virus_"
set PLUGIN xdotool search --sync --name "$TRACK_TITLE /" windowactivate
set BITWIG xdotool search --sync --name "Bitwig Studio" windowactivate


# (fish does not support multiple return values, these return variables are a workaround to make the functions easier to read)
set category ""
set tags ""
set presetname ""



########
# Functions
########


#
# argv[1]: the number of the bank to select (bank A => 1, B => 2, ...)
# argv[2]: the number of the program in the bank to select (1 -> 128)
#
function select_the_program_from_the_list 
	# Click on the DSP56300Emu 'factory preset browser' button
	$PLUGIN mousemove --window %1 $EMU_BROWSERXY[1] $EMU_BROWSERXY[2]
	xdotool click 1


	# Scroll to the desired bank
	sleep 0.1
	xdotool key Down
	for f in (seq 1 $argv[1])
		xdotool key Down
	end
	

	# Scroll to the desired program
	sleep 0.1
	xdotool key Right
	for f in (seq 2 $argv[2])
		if test $f -eq 64
			sleep 0.1
		end
		xdotool key Down
	end

	xdotool key Return
end


function copy_the_program_name
	# Click on the program name centre-top
	$PLUGIN --sync mousemove --window %1 $EMU_TITLEXY[1] $EMU_TITLEXY[2] click 1 click 1

	# Ctrl-a Ctrl-c
	xdotool key --delay 100 "ctrl+a" "ctrl+c"
	xdotool key --delay 100 Escape

	set presetname (xsel -ob 2> /dev/null | head -n 1 | xargs -0 | tr "/\?<>:|*" " " | tr -d \x7f | string trim )
end



function copy_and_map_the_category_names
	# Screenshot the Category 1 dropdown box and pipe it through tesseract OCR to get the category text

	# locate the screen coordinates of the dropbox
	sleep 0.024
	set windowid ($PLUGIN getwindowgeometry --shell | grep WINDOW= | grep -o "[[:digit:]]*")
	set x ($PLUGIN getwindowgeometry --shell | grep X= | grep -o "[[:digit:]]*")
    set y ($PLUGIN getwindowgeometry --shell | grep Y= | grep -o "[[:digit:]]*")
	# echo $windowid, $x, $y
	set width (math $EMU_CAT1XY[3]-$EMU_CAT1XY[1])
    set height (math $EMU_CAT1XY[4]-$EMU_CAT1XY[2])

	import -window $windowid -crop $width"x"$height+$EMU_CAT1XY[1]+$EMU_CAT1XY[2]! test.png

	# tesseract succeeds if you capture a few pixels taller and wider than the red box in which the text sits
	sleep 0.15

	set cat1 (tesseract test.png - --dpi 72)
	if test -z $cat1:
		set cat1 "None"
	end
	
	sleep 0.024

	# Category 2
	set width (math $EMU_CAT2XY[3]-$EMU_CAT2XY[1])
    set height (math $EMU_CAT2XY[4]-$EMU_CAT2XY[2])
	import -window $windowid -crop $width"x"$height+$EMU_CAT2XY[1]+$EMU_CAT2XY[2]! test.png

	sleep 0.15
	set cat2 (tesseract test.png - --dpi 72)
	if test -z $cat2:
		set cat2 "None"
	end


	#
	# Map the category names to a single Bitwig preset Category, and a list of tags for the preset
	#

	set cat1_category (yq -r "try .[\"$cat1\"].category" dsp_categories.yaml)
	set cat1_tags (yq -r "try .[\"$cat1\"].tags[]" dsp_categories.yaml)

	set cat2_category (yq -r "try .[\"$cat2\"].category" dsp_categories.yaml)
	set cat2_tags (yq -r "try .[\"$cat2\"].tags[]" dsp_categories.yaml)

	# Bitwig only takes one Category, so if both categories are populated, choose the first
	if test $cat1_category != "None" -a $cat2_category != "None"
		set category $cat1_category
	else if test $cat1_category != "None"
		set category $cat1_category
	else if test $cat2_category != "None"
		set category $cat2_category
	else
		set category "None"
	end
	# But if this, then that
	if test $cat2_category = "Bass"
		set tags $tags bass
	end

	# Bitwig allows multiple tags, so merge the two tags arrays
	# There is no need to implement deduplication (because the Bitwig UI will do this for us)
	set tags $cat1_tags $cat2_tags

	echo categories: $cat1 $cat2
	echo tags: $tags
end


#
# argv[1]: the number of the selected bank (bank A => 1, B => 2, ...)
# argv[2]: the number of the selected bank program (1 -> 128)
#
function save_bwpreset
	# Return to Bitwig and paste the program name into a new Bitwig preset
	sleep 0.1
	$BITWIG mousemove --sync --window %1 10 10 click 1
	xdotool type --delay 100 od
	xdotool key KP_Multiply # Use our 'Save to Library' Bitwig shortcut

	# Program name
	## Bank C Program 125 (Low) name clashes with Bank F Program 128 (Low)
	if test "$argv[1]" = "C" -a "$argv[2]" = "125"
		set presetname "$presetname (Bank C)"
	else if test "$argv[1]" = "F" -a "$argv[2]" = "128"
		set presetname "$presetname (Bank F)"
	end

	sleep 0.1
	xdotool key --delay 100 "ctrl+a" type --clearmodifiers --delay 200 -- "$presetname"
	#

	# Creator
	sleep 0.1
	xdotool key Tab type --clearmodifiers --delay 110 Access

	# Category
	set dropdown_len (wc -l bwpreset_category_dropdown.txt | cut -f 1 -d ' ')
	xdotool key Tab
	## Reposition the selected entry to the top of the list (because the dropdown will save it's current position between new bwpresets for the same instrument)
	for f in (seq 0 $dropdown_len)
		xdotool key Up
	end
	## Iterate down the list until we find the right entry
	for f in (cat bwpreset_category_dropdown.txt)
		if test $f = $category
			break
		end
		xdotool key Down
	end

	# Tags
	if test -n "$tags"
		xdotool key Tab
		xdotool key BackSpace BackSpace BackSpace BackSpace BackSpace
		xdotool key type --clearmodifiers --delay 100 "$tags "
	else
		xdotool key Tab 
		xdotool key BackSpace BackSpace BackSpace BackSpace BackSpace
		# echo No tags to enter
	end

	# Description
	xdotool key --delay 100 Tab "ctrl+a" type --delay 100 "Bank $argv[1] Program $argv[2]"

	# Tab upward and exit the dialog
	xdotool key Shift+Tab Shift+Tab
	xdotool key --delay 300 Return Return
end




########
# Main
########

# create a track
$BITWIG
xdotool type o
xdotool key "ctrl+t"

# set the track name 
xdotool type t
xdotool key "ctrl+r"; sleep 0.1
xdotool type --delay 30 "$TRACK_TITLE"
xdotool key Return

# open the instrument via the browser
xdotool type db; sleep 0.1
xdotool type --delay 30 "Dev56300Emu"
sleep 0.1
xdotool key --delay 1000 Down Return

sleep 1 # wait for the VST to load

# go to the Arp | Settings page
$PLUGIN mousemove --sync --window %1 $EMU_SETTINGSXY[1] $EMU_SETTINGSXY[2] click 1


#
# Iterate through banks C through H and run our preset making routine for each preset.
#


# Bank C
# As per our command line options, if the first argument is 1, process presets from 1 to 128
# If 100, process 100 through 128
# If 0, process none
if test $argv[1] -ne 0 
	for f in (seq $argv[1] 128)

		select_the_program_from_the_list 2 $f

		copy_the_program_name
		echo C$f: (xsel -ob 2> /dev/null | head -n 1 | xargs -0 | tr -d "/\?<>:|*")
		copy_and_map_the_category_names 
		save_bwpreset C $f

		$PLUGIN mousemove --window %1 0 0
	end
end

# Bank D
# If the second argument is x, process presets x to 128
if test $argv[2] -ne 0
	for f in (seq $argv[2] 128)

		select_the_program_from_the_list 3 $f

		copy_the_program_name

		echo D$f: (xsel -ob 2> /dev/null | head -n 1 | xargs -0 | tr -d "/\?<>:|*")
		copy_and_map_the_category_names 
		save_bwpreset D $f

		$PLUGIN mousemove --window %1 0 0
	end
end

# Bank E
if test $argv[3] -ne 0
	for f in (seq $argv[3] 128)

		select_the_program_from_the_list 4 $f

		copy_the_program_name

		echo E$f: (xsel -ob 2> /dev/null | head -n 1 | xargs -0 | tr -d "/\?<>:|*")
		copy_and_map_the_category_names 
		save_bwpreset E $f

		$PLUGIN mousemove --window %1 0 0
	end
end


if test $argv[4] -ne 0
	for f in (seq $argv[4] 128)

		select_the_program_from_the_list 5 $f

		copy_the_program_name

		echo F$f: (xsel -ob 2> /dev/null | head -n 1 | xargs -0 | tr -d "/\?<>:|*")
		copy_and_map_the_category_names 
		save_bwpreset F $f

		$PLUGIN mousemove --window %1 0 0
	end
end


if test $argv[5] -ne 0
	for f in (seq $argv[5] 128)

		select_the_program_from_the_list 6 $f

		copy_the_program_name

		echo G$f: (xsel -ob 2> /dev/null | head -n 1 | xargs -0 | tr -d "/\?<>:|*")
		copy_and_map_the_category_names 
		save_bwpreset G $f

		$PLUGIN mousemove --window %1 0 0
	end
end


if test $argv[6] -ne 0
	for f in (seq $argv[6] 128)

		select_the_program_from_the_list 7 $f

		copy_the_program_name

		echo H$f: (xsel -ob 2> /dev/null | head -n 1 | xargs -0 | tr -d "/\?<>:|*")
		copy_and_map_the_category_names 
		save_bwpreset H $f

		$PLUGIN mousemove --window %1 0 0
	end
end