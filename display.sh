#!/usr/bin/bash
TTY=/dev/ttyUSB0
DEMO=OFF
PAGE_DEBUG=d
PAGE_STATE=s
PAGE_NAME=n
PAGE_TIMEOUT=e
PAGE_COUNT=p
PAGE_TIME=t
PAGE_STATE=s
PAGE_STATE_CUST=c

count=16
pages=("svc/networking" "svc/dhcpcd" "svc/redis" "svc/apache2" "svc/nginx" "svc/mariadb" "svc/dnsmasq" "lan/nas" "lan/ccu2" "lan/router" "web/google.de" "temps/cpu" "temps/nvme" "temps/sda" "health/nvme" "health/sda" )

sc=7
pc=4

services=("networking" "dhcpcd" "redis-server" "apache2" "nginx" "mariadb" "dnsmasq")
endpoints=("nas.raven2.lan" "ccu2.raven1.lan" "darken01.raven.lan" "www.google.de")


function send() {
   echo "@:$1" | tee $TTY
   sleep .2
}


function set_name() {
   local v=$(printf '%02x' $1)
   send "${PAGE_NAME}${v}$2!"
}


function service() {
   local v=$(printf '%02x' $1)
   if [ "ON" == $DEMO ]; then
      send "${PAGE_STATE_CUST}${v}01   up!"
   elif [ "active" == `systemctl is-active $2` ]; then
      local s=$(printf '%5s' "up")
      send "${PAGE_STATE_CUST}${v}01$s!"
   else
      local s=$(printf '%5s' "down")
      send "${PAGE_STATE_CUST}${v}04$s!"
   fi
}

function reach() {
   local v=$(printf '%02x' $1)

   if [ "ON" == $DEMO ]; then
      send "${PAGE_STATE}${v}01"
   else
      ping -c 2 -W 1 "$2" > /dev/null 2>&1
      if [ $? == 0 ]; then
         send "${PAGE_STATE}${v}01"
      else
         send "${PAGE_STATE}${v}04"
      fi
   fi
}

function sens() {
   local i=$(printf '%02x' $1)

   if [ "ON" == $DEMO ]; then
      send "${PAGE_STATE_CUST}${i}01 41\dfC!"
   else
      local s=01
      local v=$(sensors | grep "$2" | sed -r 's/.+:[ \t]+\+([0-9]+)\..*/\1/g')

      if [ $v -gt $3 ]; then s=02; fi
      if [ $v -gt $4 ]; then s=03; fi

      local t=$(printf '%3s\dfC' $v)
      send "${PAGE_STATE_CUST}$i$s$t!"
   fi
}

function smartTemp() {
   local i=$(printf '%02x' $1)

   if [ "ON" == $DEMO ]; then
      send "${PAGE_STATE_CUST}${i}01 41\dfC!"
   else
      local s=01
      local v=$(sudo smartctl -a "$2" | grep "$3" | sed -r 's/[ \t]+/|/g' | cut -d'|' -f$4)

      if [ $v -gt $5 ]; then s=02; fi
      if [ $v -gt $6 ]; then s=03; fi

      local t=$(printf '%3s\dfC' $v)
      send "${PAGE_STATE_CUST}$i$s$t!"
   fi
}

function smartHealth() {
   local i=$(printf '%02x' $1)

   if [ "ON" == $DEMO ]; then
      send "${PAGE_STATE}${i}01"
   else
      local v=$(sudo smartctl -a "$2" | grep "health" | sed -r 's/[ \t]+/|/g' | cut -d'|' -f6)
      local s=01

      if [ "$v" != "PASSED" ]; then s=03; fi
      send "${PAGE_STATE}$i$s"
   fi
}

function status() {
   # set systemctl flags
   local i=0
   while [ $i -lt $sc ]; do
      service $i "${services[$i]}"
      i=$(($i + 1))
   done

   # set ping flags
   i=0
   while [ $i -lt $pc ]; do
      reach $(($i + $sc)) "${endpoints[$i]}"
      i=$(($i + 1))
   done

   # send cpu temps
   sens 11 "Package id 0" 70 95

   # send hdd temps
   smartTemp 12 "/dev/nvme0" "Temperature:" 2 70 95
   smartTemp 13 "/dev/sda" "Temperature_Celsius" 10 70 95

   # send hdd healt
   smartHealth 14 "/dev/nvme0"
   smartHealth 15 "/dev/sda"
}

function setup() {
   # set page count
   local v=$(printf '%02x' $count)
   send "${PAGE_COUNT}${v}"

   # set screen time to 2sec
   send "${PAGE_TIME}02"

   # set service timeout to 25min (0x05DC)
   send "${PAGE_TIMEOUT}05DC"

   # set the names
   local i=0
   while [ $i -lt $count ]; do
      set_name $i "${pages[$i]}"
      i=$(($i + 1))
   done

   # send the status information
   status
}

function help() {
   echo "display.sh setup|status|nightmode|daymode|help [<device>]"
   echo "   setup     .. send setup information to control display."
   echo "   status    .. acquire and send status information to display."
   echo "   nightmode .. switch to night mode to disable blinking."
   echo "   daymode   .. switch to normal display mode."
   echo "   help      .. print this help."
   echo "   demo      .. run setup command and send status "okay" for all fields without really checking.
   echo "   <device>  .. optional. the device to use as TTY output instead if /dev/ttyUSB0"
   exit 1
}

cmd="setup"
if [ $# -gt 0 ]; then
   cmd="$1"
fi

if [ $# -gt 1 ]; then
   TTY="$2"
fi

echo "Run command $cmd"

case "$cmd" in
   demo)
      DEMO=ON
      setup
      ;;

   setup)
	   setup
      ;;

   status)
	   status
      ;;

   nightmode)
      send m01
      ;;

   daymode)
      send m00
      ;;

   *)
      help
      ;;
esac
