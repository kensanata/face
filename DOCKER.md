# Docker

## Quickstart

If you don’t know anything about Docker, this is how you set it up.

```bash
# install docker on a Debian system
sudo apt install docker.io
# add the current user to the docker group
sudo adduser $(whoami) docker
# if groups doesn’t show docker, you need to log in again
su - $(whoami)
```

## Build an image

There is a Dockerfile to build this in the repository. Check out the
repository, change into the working directory, and build a docker
image, tagging it `test/face-generator`:

```bash
git clone https://alexschroeder.ch/cgit/face-generator
cd face-generator
docker build --tag test/face-generator .
```

## Running it

To start the container from this image and run `face-generator`:

```bash
docker run --publish=3020:3020 test/face-generator \
  face-generator daemon --listen "http://*:3020"
```

## Troubleshooting

If you need a new checkout of the code, you must “bust” the cache.

```bash
docker build --no-cache --tag test/face-generator .
```

To redo the image, you first have to prune the stopped containers
using it.

```bash
docker container prune
```

Then you can delete the image:

```bash
docker image rm test/face-generator
```

