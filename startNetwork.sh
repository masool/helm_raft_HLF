cd diamond-kube

echo "Tear down everything"
echo ""
echo ""
echo "Please wait..."

argo delete --all
helm delete diamond-kube --purge

echo ""

sleep 2s

./init.sh ./samples/scaled-raft-no-tls/ ./samples/chaincode/

helm install ./diamond-kube --name diamond-kube -f samples/scaled-raft-no-tls/network.yaml -f samples/scaled-raft-no-tls/crypto-config.yaml --set orderer.cluster.enabled=true --set peer.launchPods=false --set orderer.launchPods=false

sleep 2s

./collect_host_aliases.sh ./samples/scaled-raft-no-tls/

helm upgrade diamond-kube ./diamond-kube -f samples/scaled-raft-no-tls/network.yaml -f samples/scaled-raft-no-tls/crypto-config.yaml -f samples/scaled-raft-no-tls/hostAliases.yaml --set orderer.cluster.enabled=true

sleep 3m
echo ""
echo "Waiting for approx 3 minutes to create channel"
echo ""
echo ""
echo "Creating channel"
echo ""
echo ""
helm template channel-flow/ -f samples/scaled-raft-no-tls/network.yaml -f samples/scaled-raft-no-tls/crypto-config.yaml -f samples/scaled-raft-no-tls/hostAliases.yaml | argo submit - --watch

