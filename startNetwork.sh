cd fabric-kube

echo "Tear down everything"
echo ""
echo ""
echo "Please wait..."

argo delete --all
helm delete hlf-kube --purge

echp ""

sleep 2s

./init.sh ./samples/scaled-raft-no-tls/ ./samples/chaincode/

helm install ./hlf-kube --name hlf-kube -f samples/scaled-raft-no-tls/network.yaml -f samples/scaled-raft-no-tls/crypto-config.yaml --set orderer.cluster.enabled=true --set peer.launchPods=false --set orderer.launchPods=false

sleep 2s

./collect_host_aliases.sh ./samples/scaled-raft-no-tls/

helm upgrade hlf-kube ./hlf-kube -f samples/scaled-raft-no-tls/network.yaml -f samples/scaled-raft-no-tls/crypto-config.yaml -f samples/scaled-raft-no-tls/hostAliases.yaml --set orderer.cluster.enabled=true