# deploy in docker hub

login into your docker repository

```
docker login --username=your_username
```

check if the image is in your local repository
```
docker images
```

if not there add it by executing the build.sh file in this repository.
```
./build.sh
```

check the image is build correctly by listing images again
```
docker images
```

tag the image locally
```
docker tag imageID username/repo:tag
```

push it to dockerhub
```
docker push username/repo
```

check in the repo that the image is there.

