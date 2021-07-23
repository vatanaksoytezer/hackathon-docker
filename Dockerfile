FROM moveit/moveit2:foxy-source

# Make tutorial workspace
WORKDIR /root/ws_tutorial

SHELL ["/bin/bash", "-c"] 
# Clone moveit2 tutorial repos
RUN git clone https://github.com/ros-planning/moveit2_tutorials src/moveit2_tutorials -b main && \
    vcs import src < src/moveit2_tutorials/moveit2_tutorials.repos
#  Install dependencies and build moveit2_tutorials
RUN apt-get update && rosdep update && \
    source /opt/ros/foxy/setup.bash && \
    source /root/ws_moveit/install/setup.bash && \
    rosdep install -r --from-paths src --ignore-src --rosdistro foxy -y && \
    colcon build --event-handlers desktop_notification- status- --cmake-args -DCMAKE_BUILD_TYPE=Release && \
    echo "source /opt/ros/foxy/setup.bash" >> ~/.bashrc && \
    rm -rf /var/lib/apt/lists/*

# Highly recommend enabling bash completion through https://askubuntu.com/a/1026978



# docker pull moveit/moveit2:foxy-source
# docker build --tag moveit/moveit2:tutorial - < Dockerfile
# docker run -it  --name tutorial-container moveit/moveit2:tutorial /bin/bash
# docker container commit tutorial-container techtalk:tutorial
# docker stop tutorial-container
# docker start tutorial-container
# docker exec -it tutorial-container /bin/bash
# docker stop tutorial-container
# docker container rm tutorial-container
# start_docker script, joystick and tutorial demo

# docker container ..
# docker image ..
# docker ps --all
