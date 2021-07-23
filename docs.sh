#! /bin/bash
# Pull moveit/moveit2:foxy-source image from dockerhub
docker pull moveit/moveit2:foxy-source
# Push the same docker image to private registry-host on port 5000
docker image push registry-host:5000/moveit/moveit2:foxy-source/
# Build a docker image from a given Dockerfile and tags it as moveit/moveit2:tutorial
docker build --tag moveit/moveit2:tutorial - < Dockerfile
# Create an interactive container with the given image and runs /bin/bash
docker run -it  --name tutorial-container moveit/moveit2:tutorial /bin/bash
# Create an image from the container
docker container commit tutorial-container techtalk:tutorial
# Save a docker image into a tar
docker save moveit/moveit2:foxy-source > moveit2_foxy.tar
# Load a docker image from tarball
docker load < moveit2_foxy.tar

# Create an interactive container with the given image and runs /bin/bash (Only the first time!)
docker run -it  --name tutorial-container moveit/moveit2:tutorial /bin/bash
# Start an existing container
docker start tutorial-container
# Shoot an interactive terminal in the running container
docker exec -it tutorial-container /bin/bash
# Stop the container
docker stop tutorial-container
# Remove the container (will delete everthing inside it)
docker container rm tutorial-container
