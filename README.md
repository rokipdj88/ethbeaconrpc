AUTO INSTALLER ETHEREUM LOCAL RPC
```
wget https://github.com/rokipdj88/ethbeaconrpc/raw/main/ethrpc.sh -O ethrpc.sh && chmod +x ethrpc.sh && ./ethrpc.sh
```

Check your sync by running this script:
```
nano sync.sh
```
Copy & Paste
```
#!/bin/bash

echo "=== GETH SYNC STATUS ==="
curl -s -X POST --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
     -H "Content-Type: application/json" http://localhost:8545 | jq

echo ""
echo "=== BEACON SYNC STATUS ==="
curl -s http://localhost:3500/eth/v1/node/syncing | jq
```
Save CTRL X, Y & ENTER
```
chmod +x sync.sh
```
Run
```
./sync.sh
```

SEPOLIA RPC FORMAT:
```
http://Your_VPS_IP:8545
```
CONSENSUS BEACON RPC FORMAT:
```
http://Your_VPS_IP:3500
```

STOP & REMOVE PRIVATE RPC:
```
systemctl stop geth.service
systemctl disable geth.service
rm /etc/systemd/system/geth.service
rm -rf /home/geth
systemctl stop beacon.service
systemctl disable beacon.service
rm /etc/systemd/system/beacon.service
rm -rf /home/beacon
```
