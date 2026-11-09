#!/bin/bash

# SUDO_ASKPASS helper. When an installer run by zapz needs your password and
# there's no terminal to ask in (Homebrew runs pkg installers that way), sudo
# runs this, and it asks with a normal Mac password dialog. Cancel fails the
# install instead of leaving it waiting where you can't see it.

exec /usr/bin/osascript \
    -e 'on run argv' \
    -e 'activate' \
    -e 'text returned of (display dialog (item 1 of argv) default answer "" with hidden answer with title "zapz" with icon caution buttons {"Cancel", "OK"} default button "OK")' \
    -e 'end run' \
    "zapz needs your Mac password to finish installing an app." 2>/dev/null
