#!/bin/bash
# Author:       sickcodes
# Contact:      https://twitter.com/sickcodes
# Copyright:    sickcodes (C) 2021
# License:      GPLv3+

bash /var/lib/lxc/anbox/bootstrap.sh
ip link add name anbox0 type bridge
ip link set dev anbox0 up
dhcpd -4 -q -cf /etc/dhcpd.anbox.conf --no-pid anbox0
DISPLAY=:1 lxc-start -n anbox -F -- /init