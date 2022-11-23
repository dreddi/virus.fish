# virus.fish

Do you use Linux? 
Do you make music? 
Do you use the DSP56300Emu VST to emulate an Access Virus C but want its factory presets to integrate with your Bitwig Studio preset browser?

This is a fish shell script which automates the mouse and key presses needed to create a .bwpreset for each factory preset.


## Prerequisites:
- an X11 environment (tested on Ubuntu 22.04)
- sudo apt install tesseract-ocr xdotool
- Bitwig Studio (Tested on 4.3)
- DSP56300Emu (Tested on 1.2.20, VST2, Hoverland skin, Virus C rom)

also, 
- You have no Bitwig presets for DSP56300Emu already (because, we do not handle the dialog where Bitwig asks if you want to replace an existing preset)
- In Bitwig, the shortcut for 'Save to Library' must be set to Numpad *
- The default shortcuts must be set for 
	- Focus/toggle device panel (d)
	- Focus toggle/arranger window (o)
	- Focus track header (t)
	- Rename track header (Ctrl-r)
	- Selection > Select last item (End)
	- Editing > Delete (Delete)

## Usage:

1. Have a Bitwig project open.

2. Run `./virus.fish` in a separate terminal.
```
Usage:
	./virus.fish
 		This asks the program to process banks C through H entirely.

 	./virus.fish 0 0 75 1 1 1
 		This asks the program to process (i.e. if you want to resume your progress):
			Bank C not at all
			Bank D not at all
			Bank E 75-128
			Bank F 1-128
			Bank G 1-128
			Bank H 1-128
```

---

Remember to like and subscribe
