#/bin/bash!

rm -R container
mkdir container
cp ./app/* ./container
cp ./docker/* ./container
cp ./kubernetes/* ./container

docker build ./container -t wine-demo-kube:1.0



