# mini_init

An init system written in POSIX `sh`, for embedded devices.

This project is heavily tailored to [Wii-Linux](https://wii-linux.org), but can easily be adapted to any device.

It does nothing fancy.  The startup procedure looks like:
- goes through some very basic setup procedures to ensure a slightly sane environment
- enable networking
- enable zram swap
- launch a shell (`bash`) on TTY1
- when `bash` exits, display a menu that allows shutting down, rebooting, or relaunching the shell

It does **NOT** do any:
- process state tracking
- restarts
- communication with other user processes
- starting / stopping of tasks
- anything similar to "services"

It is designed for devices that need to do minimal init on boot, then have init get out of it's way until further notice.

You can use this project for any purporse, so long as you comply with the terms of it's GNU GPLv2 license.
