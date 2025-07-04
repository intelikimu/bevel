# Hyperledger Bevel - Master Helm Commands Reference

This document provides a comprehensive reference for all Helm commands used across all platforms in the Hyperledger Bevel project.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Shared Components](#shared-components)
- [Hyperledger Fabric](#hyperledger-fabric)
- [R3 Corda](#r3-corda)
- [R3 Corda Enterprise](#r3-corda-enterprise)
- [Hyperledger Besu](#hyperledger-besu)
- [Quorum](#quorum)
- [Hyperledger Indy](#hyperledger-indy)
- [Substrate](#substrate)
- [Cleanup Commands](#cleanup-commands)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### General Requirements
- Kubernetes Cluster (Minikube, EKS, AKS, GKE)
- Helm 3.x installed
- kubectl configured for cluster access
- Hashicorp Vault (if using vault)
- Ambassador Edge Stack or HAProxy (if using proxy)

### Update Dependencies
Before deploying any platform, update Helm dependencies:

```bash
# For each platform, run appropriate dependency updates
helm dependency update <chart-name>
```

## Shared Components

### Deploy Ambassador Edge Stack
```bash
helm repo add datawire https://app.getambassador.io
kubectl apply -f ../configuration/roles/setup/edge-stack/templates/aes-crds.yaml
kubectl create namespace ambassador
helm upgrade --install edge-stack datawire/edge-stack --namespace ambassador --version 8.7.2 -f ../configuration/roles/setup/edge-stack/templates/aes-custom-values.yaml
```

### Deploy HAProxy
```bash
kubectl create namespace ingress-controller
helm upgrade --install --namespace ingress-controller haproxy ./haproxy-ingress/haproxy-ingress-0.14.6.tgz --set controller.kind=DaemonSet -f ./haproxy-ingress/values.yaml
```

## Hyperledger Fabric

### Without Proxy or Vault

#### 1. Setup CA Servers and Orderers
```bash
# Update dependencies
helm dependency update fabric-ca-server
helm dependency update fabric-orderernode
helm dependency update fabric-peernode

# Install CA Server
helm upgrade --install supplychain-ca ./fabric-ca-server --namespace supplychain-net --create-namespace --values ./values/noproxy-and-novault/ca-orderer.yaml

# Install Orderers
helm upgrade --install orderer1 ./fabric-orderernode --namespace supplychain-net --values ./values/noproxy-and-novault/orderer.yaml
helm upgrade --install orderer2 ./fabric-orderernode --namespace supplychain-net --values ./values/noproxy-and-novault/orderer.yaml --set certs.settings.createConfigMaps=false
helm upgrade --install orderer3 ./fabric-orderernode --namespace supplychain-net --values ./values/noproxy-and-novault/orderer.yaml --set certs.settings.createConfigMaps=false
```

#### 2. Setup Peers
```bash
# Install Peers
helm upgrade --install peer0 ./fabric-peernode --namespace supplychain-net --values ./values/noproxy-and-novault/peer.yaml
helm upgrade --install peer1 ./fabric-peernode --namespace supplychain-net --values ./values/noproxy-and-novault/peer.yaml --set peer.gossipPeerAddress=peer0.supplychain-net:7051 --set peer.cliEnabled=true

# Install Peer CA for another organization
helm upgrade --install carrier-ca ./fabric-ca-server --namespace carrier-net --create-namespace --values ./values/noproxy-and-novault/ca-peer.yaml
helm upgrade --install peer0 ./fabric-peernode --namespace carrier-net --values ./values/noproxy-and-novault/carrier.yaml
```

#### 3. Genesis and Channel Management
```bash
# Generate Genesis Block
helm install genesis ./fabric-genesis --namespace supplychain-net --values ./values/noproxy-and-novault/genesis.yaml

# For Fabric 2.5.x - Channel Creation
helm install allchannel ./fabric-osnadmin-channel-create --namespace supplychain-net --set global.vault.type=kubernetes
helm install peer0-allchannel ./fabric-channel-join --namespace supplychain-net --set global.vault.type=kubernetes
helm install peer1-allchannel ./fabric-channel-join --namespace supplychain-net --set global.vault.type=kubernetes --set peer.name=peer1 --set peer.address=peer1.supplychain-net:7051

# For Fabric 2.2.x - Channel Creation
helm install allchannel ./fabric-channel-create --namespace carrier-net --set global.vault.type=kubernetes
helm install peer0-allchannel ./fabric-channel-join --namespace supplychain-net --set global.vault.type=kubernetes --set global.version=2.2.2
```

### With Proxy and Vault

#### 1. Setup with Authentication
```bash
kubectl create namespace supplychain-net
kubectl -n supplychain-net create secret generic roottoken --from-literal=token=<VAULT_ROOT_TOKEN>

# Install CA and Orderers
helm upgrade --install supplychain-ca ./fabric-ca-server --namespace supplychain-net --values ./values/proxy-and-vault/ca-orderer.yaml
helm upgrade --install orderer1 ./fabric-orderernode --namespace supplychain-net --values ./values/proxy-and-vault/orderer.yaml
helm upgrade --install orderer2 ./fabric-orderernode --namespace supplychain-net --values ./values/proxy-and-vault/orderer.yaml --set certs.settings.createConfigMaps=false
helm upgrade --install orderer3 ./fabric-orderernode --namespace supplychain-net --values ./values/proxy-and-vault/orderer.yaml --set certs.settings.createConfigMaps=false

# Install Peers
helm upgrade --install peer0 ./fabric-peernode --namespace supplychain-net --values ./values/proxy-and-vault/peer.yaml
helm upgrade --install peer1 ./fabric-peernode --namespace supplychain-net --values ./values/proxy-and-vault/peer.yaml --set peer.gossipPeerAddress=peer0.supplychain-net.hlf.blockchaincloudpoc-develop.com:443 --set peer.cliEnabled=true
```

#### 2. Channel Management with Proxy
```bash
# For Fabric 2.5.x
helm install allchannel ./fabric-osnadmin-channel-create --namespace supplychain-net --values ./values/proxy-and-vault/osn-create-channel.yaml
helm install peer0-allchannel ./fabric-channel-join --namespace supplychain-net --values ./values/proxy-and-vault/join-channel.yaml
helm install peer1-allchannel ./fabric-channel-join --namespace supplychain-net --values ./values/proxy-and-vault/join-channel.yaml --set peer.name=peer1 --set peer.address=peer1.supplychain-net.test.yourdomain.com:443
```

## R3 Corda

### Without Proxy or Vault
```bash
# Update dependencies
helm dependency update corda-init
helm dependency update corda-network-service
helm dependency update corda-node

# Initial setup
helm install init ./corda-init --namespace supplychain-ns --create-namespace --values ./values/noproxy-and-novault/init.yaml
helm install supplychain ./corda-network-service --namespace supplychain-ns --values ./values/noproxy-and-novault/network-service.yaml
helm install notary ./corda-node --namespace supplychain-ns --values ./values/noproxy-and-novault/notary.yaml

# Additional node in different namespace
helm install init ./corda-init --namespace manufacturer-ns --create-namespace --values ./values/noproxy-and-novault/init.yaml
helm install manufacturer ./corda-node --namespace manufacturer-ns --values ./values/noproxy-and-novault/node.yaml
```

### With Proxy and Vault
```bash
kubectl create namespace supplychain-ns
kubectl -n supplychain-ns create secret generic roottoken --from-literal=token=<VAULT_ROOT_TOKEN>

helm install init ./corda-init --namespace supplychain-ns --values ./values/proxy-and-vault/init.yaml
helm install supplychain ./corda-network-service --namespace supplychain-ns --values ./values/proxy-and-vault/network-service.yaml
helm install notary ./corda-node --namespace supplychain-ns --values ./values/proxy-and-vault/notary.yaml

# Additional node setup
kubectl create namespace manufacturer-ns
kubectl -n manufacturer-ns create secret generic roottoken --from-literal=token=<VAULT_ROOT_TOKEN>
helm install init ./corda-init --namespace manufacturer-ns --values ./values/proxy-and-vault/init-sec.yaml
helm install manufacturer ./corda-node --namespace manufacturer-ns --values ./values/proxy-and-vault/node.yaml --set nodeConf.legalName="O=Manufacturer\,OU=Manufacturer\,L=47.38/8.54/Zurich\,C=CH"
```

## R3 Corda Enterprise

### Without Proxy or Vault
```bash
# Update dependencies
helm dependency update enterprise-init
helm dependency update cenm
helm dependency update enterprise-node
helm dependency update cenm-networkmap

# Initial deployment
helm install init ./enterprise-init --namespace supplychain-ent --create-namespace --values ./values/noproxy-and-novault/init.yaml
helm install cenm ./cenm --namespace supplychain-ent --values ./values/noproxy-and-novault/cenm.yaml
helm install notary ./enterprise-node --namespace supplychain-ent --values ./values/noproxy-and-novault/notary.yaml
helm install networkmap ./cenm-networkmap --namespace supplychain-ent --values ./values/noproxy-and-novault/cenm.yaml
helm install node ./enterprise-node --namespace supplychain-ent --values ./values/noproxy-and-novault/node.yaml
```

### With Proxy and Vault
```bash
kubectl create namespace supplychain-ent
kubectl -n supplychain-ent create secret generic roottoken --from-literal=token=<VAULT_ROOT_TOKEN>

helm install init ./enterprise-init --namespace supplychain-ent --values ./values/proxy-and-vault/init.yaml
helm install cenm ./cenm --namespace supplychain-ent --values ./values/proxy-and-vault/cenm.yaml
helm install notary ./enterprise-node --namespace supplychain-ent --values ./values/proxy-and-vault/notary.yaml
helm install networkmap ./cenm-networkmap --namespace supplychain-ent --values ./values/proxy-and-vault/cenm.yaml
```

## Hyperledger Besu

### Without Proxy or Vault
```bash
# Update dependencies
helm dependency update besu-genesis
helm dependency update besu-node

# Deploy Genesis and Validators
helm install genesis ./besu-genesis --namespace supplychain-bes --create-namespace --values ./values/noproxy-and-novault/genesis.yaml
helm install validator-1 ./besu-node --namespace supplychain-bes --values ./values/noproxy-and-novault/validator.yaml
helm install validator-2 ./besu-node --namespace supplychain-bes --values ./values/noproxy-and-novault/validator.yaml
helm install validator-3 ./besu-node --namespace supplychain-bes --values ./values/noproxy-and-novault/validator.yaml
helm install validator-4 ./besu-node --namespace supplychain-bes --values ./values/noproxy-and-novault/validator.yaml

# Deploy Member Node
helm install member-1 ./besu-node --namespace supplychain-bes --values ./values/noproxy-and-novault/txnode.yaml
```

### With Proxy and Vault
```bash
kubectl create namespace supplychain-bes
kubectl -n supplychain-bes create secret generic roottoken --from-literal=token=<VAULT_ROOT_TOKEN>

helm install genesis ./besu-genesis --namespace supplychain-bes --values ./values/proxy-and-vault/genesis.yaml
helm install validator-1 ./besu-node --namespace supplychain-bes --values ./values/proxy-and-vault/validator.yaml --set global.proxy.p2p=15011
helm install validator-2 ./besu-node --namespace supplychain-bes --values ./values/proxy-and-vault/validator.yaml --set global.proxy.p2p=15012
helm install validator-3 ./besu-node --namespace supplychain-bes --values ./values/proxy-and-vault/validator.yaml --set global.proxy.p2p=15013
helm install validator-4 ./besu-node --namespace supplychain-bes --values ./values/proxy-and-vault/validator.yaml --set global.proxy.p2p=15014
helm install supplychain ./besu-node --namespace supplychain-bes --values ./values/proxy-and-vault/txnode.yaml --set global.proxy.p2p=15015 --set node.besu.identity="O=SupplyChain,OU=ValidatorOrg,L=51.50/-0.13/London,C=GB"
```

### Add Validator Node
```bash
helm install validator-5 ./besu-propose-validator --namespace supplychain-bes --values besu-propose-validator/values.yaml
```

## Quorum

### Without Proxy or Vault
```bash
# Update dependencies
helm dependency update quorum-genesis
helm dependency update quorum-node

# Deploy Genesis and Validators
helm install genesis ./quorum-genesis --namespace supplychain-quo --create-namespace --values ./values/noproxy-and-novault/genesis.yaml
helm install validator-0 ./quorum-node --namespace supplychain-quo --values ./values/noproxy-and-novault/validator.yaml
helm install validator-1 ./quorum-node --namespace supplychain-quo --values ./values/noproxy-and-novault/validator.yaml
helm install validator-2 ./quorum-node --namespace supplychain-quo --values ./values/noproxy-and-novault/validator.yaml
helm install validator-3 ./quorum-node --namespace supplychain-quo --values ./values/noproxy-and-novault/validator.yaml

# Deploy Member Node
helm install member-0 ./quorum-node --namespace supplychain-quo --values ./values/noproxy-and-novault/txnode.yaml
```

### With Proxy and Vault
```bash
kubectl create namespace supplychain-quo
kubectl -n supplychain-quo create secret generic roottoken --from-literal=token=<VAULT_ROOT_TOKEN>

helm install genesis ./quorum-genesis --namespace supplychain-quo --values ./values/proxy-and-vault/genesis.yaml
helm install validator-0 ./quorum-node --namespace supplychain-quo --values ./values/proxy-and-vault/validator.yaml --set global.proxy.p2p=15011
helm install validator-1 ./quorum-node --namespace supplychain-quo --values ./values/proxy-and-vault/validator.yaml --set global.proxy.p2p=15012
helm install validator-2 ./quorum-node --namespace supplychain-quo --values ./values/proxy-and-vault/validator.yaml --set global.proxy.p2p=15013
helm install validator-3 ./quorum-node --namespace supplychain-quo --values ./values/proxy-and-vault/validator.yaml --set global.proxy.p2p=15014
helm install member-0 ./quorum-node --namespace supplychain-quo --values ./values/proxy-and-vault/txnode.yaml --set global.proxy.p2p=15015
```

### With AWS Secrets Manager
```bash
# Prerequisites: Configure AWS Secrets Manager integration with EKS
helm install genesis ./quorum-genesis --namespace supplychain-quo --create-namespace --values ./values/noproxy-and-novault/genesis.yaml --set global.cluster.cloudNativeServices=true,global.cluster.secretManagerArn="<YOUR_AWS_SECRET_MANAGER_ROLE_ARN>",global.cluster.secretManagerRegion="<YOUR_AWS_REGION>"

helm install validator-0 ./quorum-node --namespace supplychain-quo --values ./values/noproxy-and-novault/validator.yaml --set global.cluster.cloudNativeServices=true,global.cluster.secretManagerRegion="<YOUR_AWS_REGION>"
helm install member-0 ./quorum-node --namespace supplychain-quo --values ./values/noproxy-and-novault/txnode.yaml --set global.cluster.cloudNativeServices=true,global.cluster.secretManagerRegion="<YOUR_AWS_REGION>",tessera.enabled=false
```

## Hyperledger Indy

### Without Proxy or Vault
```bash
# Update dependencies
helm dependency update indy-key-mgmt
helm dependency update indy-node

# Create Keys
helm install authority-keys ./indy-key-mgmt --namespace authority-ns --create-namespace --values ./values/noproxy-and-novault/authority-keys.yaml
helm install university-keys ./indy-key-mgmt --namespace university-ns --create-namespace --values ./values/noproxy-and-novault/university-keys.yaml

# Generate Genesis
helm install genesis ./indy-genesis --namespace authority-ns --values ./values/noproxy-and-novault/genesis.yaml
helm install genesis ./indy-genesis --namespace university-ns --values ./values/noproxy-and-novault/genesis-sec.yaml

# Deploy Stewards
helm install university-steward-1 ./indy-node --namespace university-ns --values ./values/noproxy-and-novault/steward.yaml
helm install university-steward-2 ./indy-node --namespace university-ns --values ./values/noproxy-and-novault/steward.yaml --set settings.node.externalPort=30021 --set settings.client.externalPort=30022 --set settings.node.port=30021 --set settings.client.port=30022
helm install university-steward-3 ./indy-node --namespace university-ns --values ./values/noproxy-and-novault/steward.yaml --set settings.node.externalPort=30031 --set settings.client.externalPort=30032 --set settings.node.port=30031 --set settings.client.port=30032

# Register Endorser
helm install university-endorser-id ./indy-register-identity --namespace authority-ns
```

### With Proxy and Vault
```bash
kubectl create namespace authority-ns
kubectl -n authority-ns create secret generic roottoken --from-literal=token=<VAULT_ROOT_TOKEN>
kubectl create namespace university-ns
kubectl -n university-ns create secret generic roottoken --from-literal=token=<VAULT_ROOT_TOKEN>

# Create Keys and Genesis
helm install authority-keys ./indy-key-mgmt --namespace authority-ns --values ./values/proxy-and-vault/authority-keys.yaml
helm install university-keys ./indy-key-mgmt --namespace university-ns --values ./values/proxy-and-vault/university-keys.yaml
helm install genesis ./indy-genesis --namespace authority-ns --values ./values/proxy-and-vault/genesis.yaml
helm install genesis ./indy-genesis --namespace university-ns --values ./values/proxy-and-vault/genesis-sec.yaml

# Deploy Stewards
helm install university-steward-1 ./indy-node --namespace university-ns --values ./values/proxy-and-vault/steward.yaml
helm install university-steward-2 ./indy-node --namespace university-ns --values ./values/proxy-and-vault/steward.yaml --set settings.node.externalPort=15021 --set settings.client.externalPort=15022
helm install university-steward-3 ./indy-node --namespace university-ns --values ./values/proxy-and-vault/steward.yaml --set settings.node.externalPort=15031 --set settings.client.externalPort=15032
helm install university-steward-4 ./indy-node --namespace university-ns --values ./values/proxy-and-vault/steward.yaml --set settings.node.externalPort=15041 --set settings.client.externalPort=15042
```

## Substrate

### Without Proxy or Vault
```bash
# Create namespaces
kubectl create ns oem1-subs
kubectl create ns tierone1-subs
kubectl create ns tiertwo1-subs

# Update dependencies
helm dep update substrate-key-gen
helm dep update substrate-node
helm dependency update ./dscp-ipfs-node

# Generate Keys
helm install oem-validator-1 substrate-key-gen -n oem1-subs -f values/noproxy-and-novault/key-gen.yaml --set node.isValidator=true,tags.bevel-vault-mgmt=true,tags.bevel-scripts=true
helm install oem-validator-2 substrate-key-gen -n oem1-subs -f values/noproxy-and-novault/key-gen.yaml --set node.isValidator=true
helm install oem-member-1 substrate-key-gen -n oem1-subs -f values/noproxy-and-novault/key-gen.yaml --set node.isMember=true

# Deploy Genesis
kubectl apply -f build/global-sa.yaml -n oem-subs
helm install oem-genesis substrate-genesis -n oem1-subs -f values/noproxy-and-novault/genesis.yaml

# Deploy Nodes
helm install oem-validator-1-node ./substrate-node --namespace oem1-subs --values ./values/noproxy-and-novault/node.yaml --set node.isBootnode.enabled=false,node_keys_k8s=oem-validator-1-keys
BOOTNODE_ID=$(kubectl get secret "oem-validator-1-keys" --namespace oem1-subs -o json | jq -r '.data["substrate-node-keys"]' | base64 -d | jq -r '.data.node_id')
helm install oem-validator-2-node ./substrate-node --namespace oem1-subs --values ./values/noproxy-and-novault/node.yaml --set node_keys_k8s=oem-validator-2-keys,node.isBootnode.boot_node_id=${BOOTNODE_ID}

# Deploy IPFS Nodes
helm install dscp-ipfs-node-1 ./dscp-ipfs-node --namespace oem1-subs --values ./values/noproxy-and-novault/ipfs.yaml --set config.nodeHost="oem-member-1-node-substrate-node-0"
```

### With Proxy and Vault
```bash
kubectl create ns oem-subs
kubectl create ns tierone-subs
kubectl create ns tiertwo-subs

# Generate Keys with Vault
helm install oem-validator-1 substrate-key-gen -n oem-subs -f values/proxy-and-vault/key-gen.yaml --set node.isValidator=true,tags.bevel-vault-mgmt=true,tags.bevel-scripts=true
helm install tierone-validator-3 substrate-key-gen -n tierone-subs -f values/proxy-and-vault/key-gen.yaml --set node.isValidator=true,tags.bevel-vault-mgmt=true,tags.bevel-scripts=true,global.vault.authPath="tierone",global.vault.secretPrefix="data/tierone"

# Deploy Genesis and Nodes
helm install oem-genesis substrate-genesis -n oem-subs -f values/proxy-and-vault/genesis.yaml
helm install oem-validator-1-node ./substrate-node --namespace oem-subs --values ./values/proxy-and-vault/node.yaml --set proxy.p2p=15011,node.isBootnode.enabled=false,node_keys_k8s=oem-validator-1-keys
```

## Cleanup Commands

### Hyperledger Fabric
```bash
helm uninstall --namespace supplychain-net peer1-allchannel peer0-allchannel
helm uninstall --namespace supplychain-net peer0 peer1
helm uninstall --namespace supplychain-net orderer1 orderer2 orderer3
helm uninstall --namespace supplychain-net supplychain-ca
helm uninstall --namespace supplychain-net genesis
```

### R3 Corda
```bash
helm uninstall --namespace supplychain-ns notary
helm uninstall --namespace supplychain-ns supplychain
helm uninstall --namespace supplychain-ns init
helm uninstall --namespace manufacturer-ns manufacturer
helm uninstall --namespace manufacturer-ns init
```

### R3 Corda Enterprise
```bash
helm uninstall --namespace supplychain-ent node
helm uninstall --namespace supplychain-ent notary
helm uninstall --namespace supplychain-ent cenm
helm uninstall --namespace supplychain-ent networkmap
helm uninstall --namespace supplychain-ent init
kubectl delete ns supplychain-ent
kubectl delete ns manufacturer-ent
```

### Hyperledger Besu
```bash
helm uninstall --namespace supplychain-bes validator-1
helm uninstall --namespace supplychain-bes validator-2
helm uninstall --namespace supplychain-bes validator-3
helm uninstall --namespace supplychain-bes validator-4
helm uninstall --namespace supplychain-bes supplychain
helm uninstall --namespace supplychain-bes genesis
helm uninstall --namespace carrier-bes carrier
helm uninstall --namespace carrier-bes genesis
```

### Quorum
```bash
helm uninstall --namespace supplychain-quo validator-0
helm uninstall --namespace supplychain-quo validator-1
helm uninstall --namespace supplychain-quo validator-2
helm uninstall --namespace supplychain-quo validator-3
helm uninstall --namespace supplychain-quo member-0
helm uninstall --namespace supplychain-quo genesis
```

### Hyperledger Indy
```bash
helm uninstall --namespace university-ns university-steward-1
helm uninstall --namespace university-ns university-steward-2
helm uninstall --namespace university-ns university-steward-3
helm uninstall --namespace university-ns university-steward-4
helm uninstall --namespace university-ns university-keys
helm uninstall --namespace university-ns genesis
helm uninstall --namespace authority-ns university-endorser-id
helm uninstall --namespace authority-ns authority-keys
helm uninstall --namespace authority-ns genesis
```

## Troubleshooting

### Common Helm Commands
```bash
# List all releases
helm list --all-namespaces

# Get release status
helm status <release-name> -n <namespace>

# Get release values
helm get values <release-name> -n <namespace>

# View release history
helm history <release-name> -n <namespace>

# Rollback release
helm rollback <release-name> <revision> -n <namespace>

# Debug templates
helm template <release-name> <chart-path> --values <values-file> --debug

# Dry run installation
helm install <release-name> <chart-path> --values <values-file> --dry-run
```

### Platform-Specific Debugging
```bash
# Check pod logs
kubectl logs <pod-name> -n <namespace>

# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Check service endpoints
kubectl get endpoints -n <namespace>

# Check configmaps and secrets
kubectl get configmaps,secrets -n <namespace>
```

### API Testing (Besu/Quorum)
```bash
# Get mapping for external access
kubectl get mapping --namespace <namespace>

# Test API endpoint
curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://<source-host>
```

## Notes

- Always update Helm dependencies before deploying charts
- Replace placeholder values in configuration files before deployment
- Genesis charts should be uninstalled last to prevent cleanup failures
- For production deployments, use proxy and vault configurations
- Minikube users should use LoadBalancer tunnel for external access
- Ensure proper RBAC and service account configurations for vault integration

## Support

For detailed platform-specific instructions, refer to:
- `/platforms/hyperledger-fabric/charts/README.md`
- `/platforms/r3-corda/charts/README.md`
- `/platforms/r3-corda-ent/charts/README.md`
- `/platforms/hyperledger-besu/charts/README.md`
- `/platforms/quorum/charts/README.md`
- `/platforms/hyperledger-indy/charts/README.md`
- `/platforms/substrate/charts/README.md` 