# virus.fish

Do you use Linux? 
Do you make music? 
Do you use the DSP56300Emu VST to emulate an Access Virus C but want its factory presets to integrate with your Bitwig Studio preset browser?

This is a fish shell script which automates the mouse and key presses needed to create a .bwpreset for each factory preset.


## Prerequisites:
- an X11 environment (tested on Ubuntu 20.04)
- sudo apt install tesseract-ocr
- sudo apt install xdotool
- Bitwig Studio (Tested on 4.3)
- DSP56300Emu (Tested on 1.2.20, Hoverland skin, Virus C rom)

also, 
- You have no Bitwig presets for DSP56300Emu already (because, we do not handle the dialog where Bitwig asks if you want to replace an existing preset)
- In Bitwig, the shortcut for 'Save to Library' must be set to Numpad *
- The default shortcuts must be set for 
    - focus/toggle device panel (d)
    - focus toggle/arranger window (o)
    - focus track header (t)
    - rename track header (Ctrl-r)
- You must start from a Bitwig project with no tracks open.

---

Remember to like and subscribe
