# proxl-build-docker
Dockerfile for creating a Docker image in which to build proxl.

To build docker image:
```
sudo docker image build -t mriffle/build-proxl ./
```
To build proxl:
```
sudo docker run --rm -it --user $(id -u):$(id -g) -v `pwd`:`pwd` -w `pwd` --env HOME=. --entrypoint ant mriffle/build-proxl -f ant__build_all_proxl.xml
```
