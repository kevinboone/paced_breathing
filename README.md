# paced\_breathing

## What is this?

This simple Linux Bash script assists with "paced" breathing exercises, where
one breathes in for a fixed number of seconds, and then out for fixed number of
seconds, usually for minutes at a time. These kinds of exercises are often
recommended to people who suffer from stress-related disorders, or just as an
aid to relaxation. 

The script draws a kind of moving bar-graph in the terminal to indicate the
timing of each breath. The script runs continuously, until interrupted.  It can
optionally generate rising and falling audio tones (using `sox` and `aplay`) so
it can be used without looking at the terminal.  There are plenty of ways in
which the generated audio can be tweaked to suit the user's preference.

The script takes no command-line arguments -- please see the top of the
source for the parameters that can be adjusted. Almost certainly the 
user will want to adjust `breathe_in_time` and `breathe_out_time`. 

## Limitations

This is a very simple shell script. It doesn't have the features of
proprietary paced breathing applications.

- The breathing times must be a whole number of seconds. 
- There is no way to specify "breath hold" periods in the breathing cycle,
although a couple of additional `sleep` commands would readily fix this.
- If you want to change the audio output device, you'll have to tweak
the `aplay` commands in the code.

## Legal

This simple utility is distributed under the terms of the GNU Public
Licence, v3.0. Please do with it as you see fit, at your own risk.
Please don't ask me for medical guidance ;)


