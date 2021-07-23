#!/bin/bash

display_usage() { 
    printf "Usage:\n start_docker <name_of_the_container> <name_of_the_image (optional)> <volume_path (optional)>\n"
} 

if [ -z "$1" ]
then
    display_usage
    exit 1
else
    CONTAINER_NAME=$1
    IMAGE_NAME=$2
    VOLUME_PATH=$3
    if (docker ps --all | grep -q "$CONTAINER_NAME")
    then
        xhost +local:root &> /dev/null
        echo "Found a docker container with the given name, starting $1"
        printf "\n"
        # If Docker is already running, no need to start it
        if (docker ps | grep -q "$CONTAINER_NAME")
        then
            docker exec -it "$CONTAINER_NAME" /bin/bash && \
            xhost -local:root 1>/dev/null 2>&1
        else
            docker start "$CONTAINER_NAME" 1>/dev/null 2>&1
            docker exec -it "$CONTAINER_NAME" /bin/bash && \
            xhost -local:root 1>/dev/null 2>&1
        fi

    else
        if [ -z "$2" ]
        then
            printf "Can't find docker with the given name, need image name\n"
            display_usage
            exit 1
        else
            echo "Creating docker container $1 from image $2"
            printf "\n"
            if [ -z "$3" ]
            then
                # Remove gpu stuff if there is no nvidia
                xhost +local:root &> /dev/null
                docker run -it --privileged \
                    --net=host \
                    --gpus all \
                    --env=NVIDIA_VISIBLE_DEVICES=all \
                    --env=NVIDIA_DRIVER_CAPABILITIES=all \
                    --env=DISPLAY \
                    --env=QT_X11_NO_MITSHM=1 \
                    -v /tmp/.X11-unix:/tmp/.X11-unix \
                    --name "$CONTAINER_NAME" \
                    "$IMAGE_NAME" \
                    /bin/bash
                xhost -local:root 1>/dev/null 2>&1
            else
                # Get volume absolute path and basename
                VOLUME_ABS="$(cd "$(dirname "$VOLUME_PATH")"; pwd)/$(basename "$VOLUME_PATH")" || return
                VOLUME_MNT="/root/$(basename "$VOLUME_PATH")"
                echo "Mounting directory $VOLUME_ABS into $VOLUME_MNT"
                printf "\n"
                xhost +local:root &> /dev/null
                # Remove gpu stuff if there is no nvidia
                docker run -it --privileged \
                    --net=host \
                    --gpus all \
                    --env=NVIDIA_VISIBLE_DEVICES=all \
                    --env=NVIDIA_DRIVER_CAPABILITIES=all \
                    --env=DISPLAY \
                    --env=QT_X11_NO_MITSHM=1 \
                    -v "/tmp/.X11-unix:/tmp/.X11-unix" \
                    -v "$VOLUME_ABS:$VOLUME_MNT:rw" \
                    -v "/dev:/dev:rw" \
                    --name "$CONTAINER_NAME" \
                    "$IMAGE_NAME" \
                    /bin/bash
                xhost -local:root 1>/dev/null 2>&1            
            fi
        fi
    fi
fi

