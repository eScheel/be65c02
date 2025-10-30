# BE65c02

A modified version of Ben Eaters 65c02.

This was a learning project for me to better understand how microprocessors work.
I may or may not pick this project up again in the future.

I did not make any schematics in kicad because I just got into kicad with this project.

src/main.asm is the main file and the code there does some initialization and is a simple shell.
All the src/*.s files are simply includes for the main.asm file.

The logic directory contains png files of my address decoding logic created with MS paint.

The minipro-sh folder contains scripts for burning to ROM and connecting to serial IO on NIX* environments.
On Windows I used Xgpro and putty.

Big thanks to Ben Eater for enabling me to start and get so far in this project!
https://eater.net/

I had a lot of fun doing this and hopefully someone can find some code here useful.
