#!/bin/bash

# usage:
# ./lcd.sh

# I2C addresses
backlight=0x62
character=0x3e

# backlight registers
mode1=0x00
mode2=0x01
pwm0=0x02
pwm1=0x03
pwm2=0x04
ledout=0x08

# character registers
display=0x80
letters=0x40

red=0x00
green=0x00
blue=0x00

function hex() {
  printf "0x%02x\n" "'$1"
}
function showIP() {
  # backlight
  # set to cyan

  red=0x00
  green=0xFF
  blue=0xFF

  i2cset -y 1 $backlight $pwm0 $blue   # blue
  i2cset -y 1 $backlight $pwm1 $green  # green
  i2cset -y 1 $backlight $pwm2 $red    # red
  sleep 1

  IP=$(ifconfig eth0 | grep "inet addr" | awk -F" " '{print $2}'| awk -F":" '{print $2}')
  while [ ! $IP ]; do
    sleep 1
    IP=$(ifconfig eth0 | grep "inet addr" | awk -F" " '{print $2}'| awk -F":" '{print $2}')
  done
  for i in `echo $IP | grep -o .`;
    do
      hx=$(hex $i)
      i2cset -y 1 $character  $letters $hx
    done
}
function cleardisplay() {
  red=0x00
  green=0x00
  blue=0x00

  i2cset -y 1 $backlight $pwm0 $blue   # blue
  i2cset -y 1 $backlight $pwm1 $green  # green
  i2cset -y 1 $backlight $pwm2 $red    # red

  i2cset -y 1 $character $display 0x01  # clear display
}

cleardisplay

if [[ "$1" == "start" ]]; then
  showIP
fi

if [[ "$1" == "stop" ]]; then
  cleardisplay
fi
