from argparse import ArgumentParser
import os, sys, subprocess

class ContextManager():
    def __init__(self):
        self.__use_graphics = True

    def __enter__(self):
        if self.__use_graphics:
            os.popen('xhost +local:root')

    def __exit__(self, exc_type, exc_value, exc_traceback):
        if self.__use_graphics:
            os.popen('xhost -local:root')

def main():
    parser = ArgumentParser(description='Create/launch docker containers')

    parser.add_argument('name',
                        type=str,
                        help='The name of the container to be created/started.')

    parser.add_argument('--image',
                        type=str,
                        help='The name of the image to use when creating the container.',
                        required=False)
    parser.add_argument('--nvidia',
                        action='store_true',
                        help='Adds arguments to "docker run" to support NVIDIA GPUs.')
    parser.add_argument('--cmd',
                        type=str,
                        help='The command to run (interactively) in the Docker container.',
                        default='/bin/bash')

    args = parser.parse_args()

    # Create the ContextManager
    cm = ContextManager()

    # Add Docker arguments for NVIDIA GPUs, if applicable.
    nvidia_args = list()
    if args.nvidia:
        nvidia_args = [
            '--gpus', 'all',
            '--env=NVIDIA_VISIBLE_DEVICES=all',
            '--env=NVIDIA_DRIVER_CAPABILITIES=all',
        ]

    # If no container with the given name exists, then create it.
    if not containerExists(args.name):
        print('Can\'t find Docker container with the given name.')
        if not args.image:
            print('--image is required when container does not already exist.')
            sys.exit(-1)

        print(f'Creating docker container {args.name} from image {args.image}.')
        with cm:
            subprocess.call(['docker',
                             'run',
                             '-it',
                             '--privileged',
                             '--net=host',] + \
                            nvidia_args + \
                            ['--env=DISPLAY',
                             '--env=QT_X11_NO_MITSHM=1',
                             '-v', '/tmp/.X11-unix:/tmp/.X11-unix',
                             '--name',  f'{args.name}',
                             args.image,
                             args.cmd])
    else:
        # If the container isn't running, then start it.
        print(f'Found a Docker container named {args.name}.')
        if not containerIsRunning(args.name):
            print(f'Starting {args.name}.')
            subprocess.call(['docker',
                             'start',
                             args.name])

        # Enter the container.
        with cm:
            subprocess.call(['docker',
                             'exec',
                             '-it',
                             args.name,
                             args.cmd])


def containerExists(name):
    """
    Returns True if a Docker container with the given name already
    exists, False otherwise.
    """
    # Get a list of all the existing containers.
    output = os.popen('docker ps --all | tail -n+2').read()
    containers = list()
    for line in output.split('\n'):
        if not line:
            continue
        containers.append(line.split()[-1])

    return name in containers


def containerIsRunning(name):
    """
    Returns True if a Docker container with the given name is running,
    False otherwise.
    """
    # Get a list of all the running containers.
    output = os.popen('docker ps | tail -n+2').read()
    running_containers = list()
    for line in output.split('\n'):
        if not line:
            continue
        running_containers.append(line.split()[-1])

    return name in running_containers

if __name__ == '__main__':
    main()
