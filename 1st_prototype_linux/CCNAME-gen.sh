export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}


configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID demochannel -asOrg Org1MSP
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx -channelID demochannel -asOrg Org2MSP

echo "anchor peers  tx files created"

docker exec cli-peer0.org1 bash -c 'bash scripts/1peercli.sh create -c demochannel'
docker exec -it cli-peer0.org1 bash -c 'cp demochannel.block ./channel-artifacts/'

echo "channel created"
docker exec cli-peer0.org1 bash -c 'peer channel join -b channel-artifacts/demochannel.block'
docker exec cli-peer0.org2 bash -c 'peer channel join -b channel-artifacts/demochannel.block'

echo "peers joined" docker exec cli-peer0.org1 bash -c 'peer channel list'


docker exec cli-peer0.org1 bash -c 'peer channel update -o orderer0.example.com:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/tlsca.example.com-cert.pem -c demochannel -f ./channel-artifacts/Org1MSPanchors.tx'
docker exec cli-peer0.org2 bash -c 'peer channel update -o orderer0.example.com:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/tlsca.example.com-cert.pem -c demochannel -f ./channel-artifacts/Org2MSPanchors.tx'

echo " anchor peers updated"

docker exec -it cli-peer0.org1 bash -c 'cp demochannel.block ./channel-artifacts/'

docker exec -it cli-peer0.org1 bash -c 'peer lifecycle chaincode package transactionv1.tar.gz --path /opt/gopath/src/transactionv1 --lang golang --label transactionv1_1'
docker exec -it cli-peer0.org2 bash -c 'peer lifecycle chaincode package transactionv1.tar.gz --path /opt/gopath/src/transactionv1 --lang golang --label transactionv1_1'

docker exec -it cli-peer0.org1 bash -c 'ls'

docker exec -it cli-peer0.org1 bash -c 'peer lifecycle chaincode install transactionv1.tar.gz &> pkg.txt'
docker exec -it cli-peer0.org2 bash -c 'peer lifecycle chaincode install transactionv1.tar.gz &> pkg.txt'

docker exec -it cli-peer0.org1 bash -c 'peer lifecycle chaincode approveformyorg -o orderer0.example.com:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/tlsca.example.com-cert.pem --channelID demochannel --name transactionv1 --version 1.0 --sequence 1 --package-id $(tail -n 1 pkg.txt | awk '\''NF>1{print $NF}'\'')'
docker exec -it cli-peer0.org2 bash -c 'peer lifecycle chaincode approveformyorg -o orderer0.example.com:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/tlsca.example.com-cert.pem --channelID demochannel --name transactionv1 --version 1.0 --sequence 1 --package-id $(tail -n 1 pkg.txt | awk '\''NF>1{print $NF}'\'')'
docker exec -it cli-peer0.org1 bash -c 'peer lifecycle chaincode commit -o orderer0.example.com:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/tlsca.example.com-cert.pem --channelID demochannel --name transactionv1 --version 1.0 --sequence 1'

# docker exec -it cli-peer0.org2 bash -c 'peer lifecycle chaincode commit -o orderer0.example.com:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/tlsca.example.com-cert.pem --channelID demochannel --name transactionv1 --version 1.0 --sequence 1'
