# Hyperledger Fabric meets Kubernetes
![Fabric Meets K8S](https://raft-fabric-kube.s3-eu-west-1.amazonaws.com/images/fabric_meets_k8s.png)


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
- Host: orderer0.groeifabriek.nl
  Port: 7059
```
Raft orderers mutually authenticate each other so they always need TLS for inter-orderer communication. That's why disabling TLS globally requires Raft orderers communicate each other over another port instead of client-facing orderer port (7050). We enable this behavior by passing the argument `orderer.cluster.enabled=true` to hlf-kube chart. 

No other change is required. Any client of orderer, either application or Argo flows or whatever, will still use the client-facing port (7050)

Let's launch the Raft network without TLS. First tear down everything as usual:
```
argo delete --all
helm delete hlf-kube --purge
```
Wait a bit until all pods are terminated, then create necessary stuff:
```
./init.sh ./samples/scaled-raft-no-tls/ ./samples/chaincode/
```

Luanch the Raft based Fabric network in broken state (only because of `useActualDomains=true`)
```
helm install ./hlf-kube --name hlf-kube -f samples/scaled-raft-no-tls/network.yaml -f samples/scaled-raft-no-tls/crypto-config.yaml --set orderer.cluster.enabled=true --set peer.launchPods=false --set orderer.launchPods=false
```

Collect the host aliases:
```
./collect_host_aliases.sh ./samples/scaled-raft-no-tls/
```
 
Then update the network with host aliases:
``` 
helm upgrade hlf-kube ./hlf-kube -f samples/scaled-raft-no-tls/network.yaml -f samples/scaled-raft-no-tls/crypto-config.yaml -f samples/scaled-raft-no-tls/hostAliases.yaml --set orderer.cluster.enabled=true
```
Again lets wait for all pods are up and running:

```
kubectl get pod --watch
```

Congrulations you have a running scaled up HL Fabric network in Kubernetes, with 3 Raft orderer nodes spanning 2 Orderer organizations and 2 peers per organization. Since TLS is disabled, your application can use them without even noticing there are 3 Orderer nodes and 2 peers per organization.

Lets create the channels:
```
helm template channel-flow/ -f samples/scaled-raft-no-tls/network.yaml -f samples/scaled-raft-no-tls/crypto-config.yaml -f samples/scaled-raft-no-tls/hostAliases.yaml | argo submit - --watch
```

And install chaincodes:
```
helm template chaincode-flow/ -f samples/scaled-raft-no-tls/network.yaml -f samples/scaled-raft-no-tls/crypto-config.yaml -f samples/scaled-raft-no-tls/hostAliases.yaml | argo submit - --watch
```

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