# Docker
_start_docker_completions()
{
    local IFS=$'\n'
    local LASTCHAR=' '
    case $COMP_CWORD in
        1)
            COMPREPLY=($(compgen -W "$(docker ps --all --format "{{.Names}}" | sed 's/\t//')" -- "${COMP_WORDS[1]}"));;
        2)
            COMPREPLY=($(compgen -W "$(docker ps --all --format "{{.Image}}" | sed 's/\t//')" -- "${COMP_WORDS[2]}"));;
        3)
            COMPREPLY=($(compgen -o plusdirs -f -- "${COMP_WORDS[3]}"))
            if [ ${#COMPREPLY[@]} = 1 ]; then
                [ -d "$COMPREPLY" ] && LASTCHAR=/
                COMPREPLY=$(printf %q%s "$COMPREPLY" "$LASTCHAR")
            else
                for ((i=0; i < ${#COMPREPLY[@]}; i++)); do
                    [ -d "${COMPREPLY[$i]}" ] && COMPREPLY[$i]=${COMPREPLY[$i]}/
                done
            fi
    esac
}

# Tiny improvements on the gui-docker of moveit, also less flexible & will depend of nvidia-docker2
function start_docker
{

  function check_nvidia2() 
  {
    # If we don't have an NVIDIA graphics card, bail out
    lspci | grep -qi "vga .*nvidia" || return 1
    # If we don't have the nvidia runtime, bail out
    if ! docker -D info | grep -qi "runtimes.* nvidia" ; then
       echo "nvidia-docker v2 not installed (see https://github.com/NVIDIA/nvidia-docker/wiki)"
       return 2
    fi
    echo "found nvidia-docker v2"
    return 0
  }

  function check_dri() 
  {
      # If there is no /dev/dri, bail out
      test -d /dev/dri || return 1
  }

  display_docker_usage() 
  { 
    printf "Usage:\n start_docker <name_of_the_container> <name_of_the_image (optional)> <volume_path (optional)>\n"
  }

  # transfer_x11_permissions

  # Probe for nvidia-docker (version 2 or 1)
  check_nvidia2 || check_dri || echo "No supported graphics card found"

  if [ -z "$1" ]
  then
      display_docker_usage
      exit 1
  else
      CONTAINER_NAME=$1
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
              printf "Can't find docker with the given name, need the state docker image as well\n"
              display_docker_usage
              exit 1
          else
              IMAGE_NAME=$2
              echo "Creating docker container $1 from image $2"
              printf "\n"
              if [ -z "$3" ]
              then
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
                  VOLUME_PATH=$3
                  # Get volume absolute path and basename
                  VOLUME_ABS="$(cd "$(dirname "$VOLUME_PATH")"; pwd)/$(basename "$VOLUME_PATH")" || return
                  VOLUME_MNT="/root/$(basename "$VOLUME_PATH")"
                  echo "Mounting directory $VOLUME_ABS into $VOLUME_MNT"
                  printf "\n"
                  xhost +local:root &> /dev/null
                  docker run -it --privileged \
                      --net=host \
                      --gpus all \
                      --env=NVIDIA_VISIBLE_DEVICES=all \
                      --env=NVIDIA_DRIVER_CAPABILITIES=all \
                      --env=DISPLAY \
                      --env=QT_X11_NO_MITSHM=1 \
                      -v "/tmp/.X11-unix:/tmp/.X11-unix" \
                      -v "$VOLUME_ABS:$VOLUME_MNT:rw" \
                      --name "$CONTAINER_NAME" \
                      "$IMAGE_NAME" \
                      /bin/bash
                  xhost -local:root 1>/dev/null 2>&1            
              fi
          fi
      fi
  fi
}

complete -o nospace -F _start_docker_completions start_docker