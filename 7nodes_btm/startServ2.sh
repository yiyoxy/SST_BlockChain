#!/bin/bash
set -u
set -e

cd /root/nodes
nohup node network.js >/root/network.log 2>&1&

echo "started network monitor"

cd /ATMC/bank_b_ATM001

nohup node app.js >/root/atmc1.log 2>&1&

echo "started ATMC1"

cd /ATMC/bank_b_ATM002

nohup node app.js >/root/atmc2.log 2>&1&

echo "started ATMC2"

cd /root/nodes

nohup node blockTrx.js >/root/blockTrx.log 2>&1&
echo "started block trx records"

