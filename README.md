# USB-Mon / Clients

Ever liked to monitor a PC or Home Server with a small LCD display?
USB-Mon does it on a simple way.

## In a Nutshell

This repository holds the client software scripts for simple monitoring services, connections, temperatures or what you like to monitor with USB-Mon LCD Panel.

## How to Build

Nope. There is nothing to build here.

## How to Use

### display.sh \<command>

This shell script provides multiple features which are explined below:

#### setup

The setup command prepares the monitoring display with number of pages, page texts, page flip time and so on. To do so it sends multiple configuration commands to display's UART port.<br/>

***display.sh setup*** is normally run using a cron job or systemd at the startup of your machin. 

#### status

The status command executes some tests, which may serve as inspiration for your monitoring needs.
I currently use tools like:

- systemctl status \<service>
- ping \<somehost>
- sensors
- smartctl -a /dev/\<somedrive>

Results of these tests are being sent as status commands to the display's UART interface.

***display.sh status*** should run repeatedly at a regulare base e.g. every 15min in order to keep the display in validated state. Please see the related *usbmon.avr* repository to find out, how to set the expiry time for pages. 

#### help

Command ***display.sh help*** just prints a short help.

# Licensing
In case you intend any use of this piece of software please read and accept the license agreement in file /LICENSE.