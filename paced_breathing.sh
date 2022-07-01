#!/bin/bash

# This simple Bash script assists with "paced" breathing exercises, where
#   one breaths in for a fixed number of seconds, and then out for 
#   a fixed number of seconds. It draws a kind of bar-graph to indicate
#   the timing of the breath. The script runs continuously, until interrupted.

# Copyright (c)2022 Kevin Boone, released under the terms of the GNU 
#  public licence, V3.0

# ====================== CONFIGURATION =====================================

# TODO: expose some of these settings as command-line arguments.

# Number of seconds to breath in (must be a whole number)

breathe_in_time=2 

# Number of seconds to breath out (must be a whole number)
breathe_out_time=4 

# Number of columns in the terminal to use for the progress indicator.
columns=40

# Set use_tonegen (to anything) if you want to use sox and aplay to
#  accompany the bargraph display with a rising-pitch and falling-pitch
#  sound to indicate breathing in and breathing out. If use_tonegen is
#  set, the the parameters following it are also used
use_tonegen=1

# tone_gen_latency is the time, in milliseconds, by which the generated
#  tones are less than the specified breath times. This is an important
#  setting because we play the tones from audio files using aplay. aplay
#  takes some time to start and stop so, if we make the audio file as
#  long as the breathing time, there's a chance that the sounds will
#  overlap. The value of this setting depends on the speed of the host
#  system and its load. 200 msec is probably a good starting point. 
#  Longer is safer but, of course, there will be gaps in the audio.
tone_gen_latency=200

# Set the names of the generated audio files. Including the process ID
#  ($$) in the name allows multiple users to use the utility concurrently,
#  in the unlikely event that this would be necessary.
rising_tone_file=/tmp/rising_$$.wav
falling_tone_file=/tmp/falling_$$.wav

# Set the frequencies (Hz) of the endpoints of the rising and falling
#  pitches
tone_high=300
tone_low=150

# ====================== FUNCTIONS =========================================

# 'div' is a function that divides two integers, and produces a
#  fixed-precision decimal result. Bash does not provide any 
#  non-integer arithmetic support. It also does not allow a function
#  to return a string value. So the function writes its output to
#  stdout. The caller should invoke the function in such a way
#  as to capture stdout; for example "result=$(div 2 5)"
# The function only handles non-negative numbers. If the denominator
#  is zero, it returns "?" 
# We need this function because not all Linux systems provide a shell
#  command that sleeps for a certain number of milliseconds or microseconds.
#  However, all modern systems have a sleep(1) that takes a fractional number
#  of seconds.
function div 
  {
  local numerator=$1
  local denominator=$2
  local decimal_places=5
  if [ $denominator -eq 0 ]; then 
     echo "?" # Can't divide by zero
     exit 
  fi
  # Multiply the numerator by a large number, and then divide by the
  #  denominator. This will give us a division result that is an integer,
  #  scaled by the original large number. This way we keep all the
  #  math in integers.
  (( dp_exp = 10**decimal_places ))
  (( scaled_result = numerator * dp_exp / denominator)); 
  # Get the whole-number part of the result -- Bash division returns
  #  the next-lowest whole number
  (( whole_number_part = scaled_result / dp_exp));
  # Get the fractional part of the result, but bear in mind that it is
  #  scaled up
  (( scaled_fractional_part = scaled_result - whole_number_part * dp_exp));
  # Work out the number of zeros to put in front of the decimal point
  # (NB: ${#XXX} is the length of XXX
  (( dp_lzeros = decimal_places - ${#scaled_fractional_part}))
  # Use printf to write the fraction part, padded with the calculated
  #  number of zeros
  printf -v scaled_fractional_part_padded \
     "%.${dp_lzeros}d$scaled_fractional_part"
  # The final result is the whole-number part, followed by a decimal point,
  #   followed by the fractional part padded with zeros
  echo $whole_number_part.$scaled_fractional_part_padded
  }

# Wait for a specified number of milliseconds. Since modern implementations 
#  of sleep(1) take a fractional number of seconds, we just divide the 
#  millisecond value by 1000
function sleep_ms 
  {
  ms=$(div $1 1000)
  sleep $ms;
  }

# Draw the bargraph to show the time elapsing. We draw a fixed boundary
#  of the form [.....] and then fill it with # characters as time 
#  passes. To do this filling in, we have to print a carriage return
#   "\r" to bring the cursor back to the start of the line, without 
#  erasing the ] character. I guess we could also print non-destructive
#  backspaces, but the behaviour of these is rather terminal-dependent.
function draw_bargraph 
  {
  sec=$1;
  caption="$2"
  # Draw the outline which we will fill in. 
  echo -n "$caption"
  echo -n " ["
  for i in $(seq 2 $columns); do echo -n " "; done
  echo -n " ]"
  printf "\r" 
  echo -n "$caption"
  echo -n " ["
  # Now write the specified number of # characters, waiting the 
  #  specified number of millisceonds between each.
  for x in $(seq 1 $columns); do
    echo -n "#"
    sleep $sec
  done
  echo "" 
  }

# ctrl_c() is called in the event on an interrupt. All we need to do here
#   is to delete the audio files we created at start-up.
function ctrl_c
  {
  if [ -n "$use_tonegen" ] ; then
    rm -f $rising_tone_file 
    rm -f $falling_tone_file 
  fi
  exit
  }

# ====================== START OF SCRIPT ===================================

# Work out the breathe in and breathe out times in milliseconds. Note that,
#  so long as the values are whole numbers, this is an integer operation,
#  which Bash can do.
(( breathe_in_time_msec = $breathe_in_time * 1000 ))
(( breathe_out_time_msec = $breathe_out_time * 1000 ))

# Work out the number of milliseconds between drawing each # in the 
#  bargraph display. Because the millisecond times will always (in practice)
#  be much larger than the number of screen columns, these calculations
#  also produce a near-integer result, even though they are divisions.
(( in_msec_per_col = $breathe_in_time_msec / $columns ))
(( out_msec_per_col = $breathe_out_time_msec / $columns ))

in_sec_per_col=$(div $in_msec_per_col 1000)
out_sec_per_col=$(div $out_msec_per_col 1000)

if [ -n "$use_tonegen" ] ; then

  # Working out the durations of the rising and falling tones, in msec,
  #  which are a bit shorter than the breathing periods
  (( in_tone_duration = $breathe_in_time_msec - $tone_gen_latency))
  (( out_tone_duration = $breathe_out_time_msec - $tone_gen_latency))

  # Convert these tone duration to seconds (which may include a fraction), 
  #   which is what sox needs
  in_tone_duration_sec=$(div $in_tone_duration 1000)
  out_tone_duration_sec=$(div $out_tone_duration 1000)

  # Use "sox synth" to generate the tones, storing the results in wav files.
  # We only need to do this once in the life of the script. The same files
  #   are played on each breathing cycle.
  sox -n $rising_tone_file \
     synth $in_tone_duration_sec sine $tone_low:$tone_high fade 0.1 0
  sox -n $falling_tone_file \
     synth $out_tone_duration_sec sine $tone_high:$tone_low fade 0.1 0
fi

# Trap interrupts, so we can clean up
trap ctrl_c INT

# Now just repeat the breath-in, breath-out bargraphs until interrupted.
while true ; do
  if [ -n "$use_tonegen" ] ; then
    aplay $rising_tone_file >& /dev/null & 
  fi
  draw_bargraph $in_sec_per_col "IN " 
  if [ -n "$use_tonegen" ] ; then
    aplay $falling_tone_file >& /dev/null &
  fi
  draw_bargraph $out_sec_per_col "OUT" 
done

