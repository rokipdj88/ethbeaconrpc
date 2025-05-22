#!/bin/bash
set -e

echo "==> 1. Updating system & installing dependencies..."
apt-get update && apt-get upgrade -y
apt install -y curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev screen coreutils software-properties-common ufw

echo "==> 2. Installing Docker..."
source <(wget -O - https://raw.githubusercontent.com/frianowzki/installer/main/docker.sh)
groupadd docker || true
usermod -aG docker $(whoami)
newgrp docker

echo "==> 3. Installing Aztec Sequencer..."
bash -i <(curl -s https://install.aztec.network)
echo 'export PATH=$PATH:/root/.aztec/bin' >> ~/.bashrc
source ~/.bashrc
aztec-up alpha-testnet

echo "==> 4. Setting up UFW firewall..."
ufw allow 8545/tcp
ufw allow 3500/tcp
ufw allow 4000/tcp
ufw allow 30303/tcp
ufw allow 30303/udp
ufw allow 12000/udp
ufw allow 13000/tcp
ufw allow 22/tcp
ufw allow 443/tcp
ufw --force enable
ufw status

echo "==> 5. Adding users and groups..."
adduser --home /home/geth --disabled-password --gecos 'Geth Client' geth || true
adduser --home /home/beacon --disabled-password --gecos 'Prysm Beacon Client' beacon || true
groupadd eth || true
usermod -a -G eth geth
usermod -a -G eth beacon

echo "==> 6. Creating JWT secret..."
mkdir -p /var/lib/secrets
chgrp -R eth /var/lib/ /var/lib/secrets
chmod 750 /var/lib/ /var/lib/secrets
openssl rand -hex 32 | tr -d '\n' | tee /var/lib/secrets/jwt.hex > /dev/null
chown root:eth /var/lib/secrets/jwt.hex
chmod 640 /var/lib/secrets/jwt.hex

echo "==> 7. Creating data directories..."
sudo -u geth mkdir -p /home/geth/geth
sudo -u beacon mkdir -p /home/beacon/beacon

echo "==> 8. Installing Ethereum & Geth..."
add-apt-repository -y ppa:ethereum/ethereum
apt-get update
apt-get install -y ethereum
wget https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.15.11-36b2371c.tar.gz
tar -xvf geth-linux-amd64-1.15.11-36b2371c.tar.gz
mv geth-linux-amd64-1.15.11-36b2371c/geth /usr/bin/geth

echo "==> 9. Creating Geth service..."
cat <<EOF >/etc/systemd/system/geth.service
[Unit]
Description=Geth
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
Restart=always
RestartSec=5s
User=geth
WorkingDirectory=/home/geth
ExecStart=/usr/bin/geth \\
  --sepolia \\
  --http \\
  --http.addr "0.0.0.0" \\
  --http.port 8545 \\
  --http.api "eth,net,engine,admin" \\
  --authrpc.addr "127.0.0.1" --authrpc.port 8551 \\
  --http.corsdomain "*" \\
  --http.vhosts "*" \\
  --datadir /home/geth/geth \\
  --authrpc.jwtsecret /var/lib/secrets/jwt.hex

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now geth
systemctl status geth --no-pager

echo "==> 10. Installing Prysm Beacon..."
sudo -u beacon mkdir -p /home/beacon/bin
sudo -u beacon curl -s https://raw.githubusercontent.com/prysmaticlabs/prysm/master/prysm.sh -o /home/beacon/bin/prysm.sh
sudo -u beacon chmod +x /home/beacon/bin/prysm.sh

cat <<EOF >/etc/systemd/system/beacon.service
[Unit]
Description=Prysm Beacon
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
Restart=always
RestartSec=5s
User=beacon
ExecStart=/home/beacon/bin/prysm.sh beacon-chain \\
  --sepolia \\
  --http-modules=beacon,config,node,validator \\
  --rpc-host=0.0.0.0 --rpc-port=4000 \\
  --grpc-gateway-host=0.0.0.0 --grpc-gateway-port=3500 \\
  --datadir /home/beacon/beacon \\
  --execution-endpoint=http://127.0.0.1:8551 \\
  --jwt-secret=/var/lib/secrets/jwt.hex \\
  --checkpoint-sync-url=https://checkpoint-sync.sepolia.ethpandaops.io/ \\
  --genesis-beacon-api-url=https://checkpoint-sync.sepolia.ethpandaops.io/ \\
  --accept-terms-of-use

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now beacon
systemctl status beacon --no-pager

echo "✅ Setup selesai. Tunggu sinkronisasi Geth & Beacon (bisa beberapa jam)."
