# Hyperledger Fabric meets Kubernetes
![Fabric Meets K8S](https://raft-fabric-kube.s3-eu-west-1.amazonaws.com/images/fabric_meets_k8s.png)

## [Requirements](#requirements)
* A running Kubernetes cluster, Minikube should also work, but not tested
* [HL Fabric binaries](https://hyperledger-fabric.readthedocs.io/en/release-1.4/install.html)
* [Helm](https://github.com/helm/helm/releases/tag/v2.16.0), 2.16 or newer 2.xx versions
* [jq](https://stedolan.github.io/jq/download/) 1.5+ and [yq](https://pypi.org/project/yq/) 2.6+
* [Argo](https://github.com/argoproj/argo), both CLI and Controller 2.4.0+
* [Minio](https://github.com/argoproj/argo/blob/master/docs/configure-artifact-repository.md), only required for backup/restore and new-peer-org flows
* Run all the commands in *fabric-kube* folder
* AWS EKS users please also apply this [fix](https://github.com/APGGroeiFabriek/PIVT/issues/1)

### [Scaled-up Raft network without TLS](#scaled-up-raft-network-without-tls)

This sample has the same topology with scaled-up Raft network, but does not enable TLS globally. This is possible since Fabric 1.4.5. In the previous versions, enabling TLS globally was mandatory for Raft orderers.

You will notice the below entries in [network.yaml](fabric-kube/samples/scaled-raft-no-tls/network.yaml) file:
```
tlsEnabled: false
useActualDomains: true
```
TLS is disabled by default but still put in this file to be explicit. Using actual domain names is not mandatory but I believe is a good practice.

In [configtx.yaml](fabric-kube/samples/scaled-raft-no-tls/configtx.yaml#L270-L282) file, you will notice Raft consenters are using a different port:
```
- Host: orderer0.diamond.nl
  Port: 7059
```
Raft orderers mutually authenticate each other so they always need TLS for inter-orderer communication. That's why disabling TLS globally requires Raft orderers communicate each other over another port instead of client-facing orderer port (7050). We enable this behavior by passing the argument `orderer.cluster.enabled=true` to diamond-kube chart. 

No other change is required. Any client of orderer, either application or Argo flows or whatever, will still use the client-facing port (7050)

Let's launch the Raft network without TLS. First tear down everything as usual:
```
argo delete --all
helm delete diamond-kube --purge
```
Wait a bit until all pods are terminated, then create necessary stuff:
```
./init.sh ./samples/scaled-raft-no-tls/ ./samples/chaincode/
```

Luanch the Raft based Fabric network in broken state (only because of `useActualDomains=true`)
```
helm install ./diamond-kube --name diamond-kube -f samples/scaled-raft-no-tls/network.yaml -f samples/scaled-raft-no-tls/crypto-config.yaml --set orderer.cluster.enabled=true --set peer.launchPods=false --set orderer.launchPods=false
```

Collect the host aliases:
```
./collect_host_aliases.sh ./samples/scaled-raft-no-tls/
```
 
Then update the network with host aliases:
``` 
helm upgrade diamond-kube ./diamond-kube -f samples/scaled-raft-no-tls/network.yaml -f samples/scaled-raft-no-tls/crypto-config.yaml -f samples/scaled-raft-no-tls/hostAliases.yaml --set orderer.cluster.enabled=true
```
Again lets wait for all pods are up and running:

```
kubectl get pod --watch
```

Congrulations you have a running scaled up HL Fabric network in Kubernetes, with 3 Raft orderer nodes spanning 2 Orderer organizations and 2 peers per organization. Since TLS is disabled, your application can use them without even noticing there are 3 Orderer nodes and 2 peers per organization.

### [Creating channels](#creating-channels)

Next lets create channels, join peers to channels and update channels for Anchor peers:
```
helm template channel-flow/ -f samples/scaled-raft-no-tls/network.yaml -f samples/scaled-raft-no-tls/crypto-config.yaml -f samples/scaled-raft-no-tls/hostAliases.yaml | argo submit - --watch
```
Channel flow is declarative and idempotent. You can run it many times. It will create the channel only if it doesn't exist, join peers to channels only if they didn't join yet, etc.

Install steps may fail even many times, nevermind about it, it's a known Fabric bug, the flow will retry it and eventually succeed.

### Option 2 to run the network

## Terminal 1

```
chmod 777 startNetwork.sh
./startNetwork.sh
```

## Terminal 2

```
kubectl get pod --watch
```