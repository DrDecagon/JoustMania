#!/bin/bash

setup() {
    # Prevent apt from prompting us about restarting services.
    export DEBIAN_FRONTEND=noninteractive
    HOMENAME=`logname`
    HOMEDIR=/home/$HOMENAME
    cd $HOMEDIR
    sudo apt-get install -y espeak

    espeak "starting system update"
    sudo apt-get update -y || exit -1
    sudo eatmydata apt-get upgrade -y || exit -1

    espeak "Installing required dependencies"
    #TODO: remove pyaudio and dependencies
    #install components
    sudo eatmydata apt-get install -y  \
        libdpkg-perl libsdl1.2-dev libsdl-mixer1.2-dev libsdl-sound1.2-dev \
        libportmidi-dev portaudio19-dev \
        libsdl-image1.2-dev libsdl-ttf2.0-dev \
        libblas-dev liblapack-dev \
        bluez bluez-tools rfkill supervisor cmake ffmpeg \
        libudev-dev swig libbluetooth-dev \
        alsa-utils alsa-tools libasound2-dev libsdl2-mixer-2.0-0 \
        libdbus-glib-1-dev libatlas-base-dev || exit -1
        #python3 python3-pip python3-pkg-resources python3-setuptools python-dbus-dev \

    espeak "Installing P S move A.P.I. dependencies"
    #install components for psmoveapi
    sudo eatmydata apt-get install -y \
        build-essential \
        libv4l-dev libopencv-dev \
        libudev-dev libbluetooth-dev \
        libusb-dev || exit -1

    espeak "Installing software libraries"
    VENV=$HOMEDIR/JoustMania/venv
    # We install nearly all python deps in the virtualenv to avoid concflicts with system,
    # except...
    sudo eatmydata apt-get install -y libasound2-dev libasound2 cmake || exit -1

    sudo eatmydata apt-get install -y python3-dev || exit -1
    if command -v python3.11 &> /dev/null ; then
        echo "Python3.11 already installed"
        espeak "Python 3.11 already installed"
    else
        espeak "installing python installation dependencies"
        sudo eatmydata apt install -y libffi-dev libbz2-dev liblzma-dev libsqlite3-dev libncurses5-dev libgdbm-dev \
            zlib1g-dev libreadline-dev libssl-dev tk-dev libncursesw5-dev libc6-dev openssl || exit -1
        espeak "downloading python 3.11"
        eatmydata wget https://www.python.org/ftp/python/3.11.4/Python-3.11.4.tgz
        tar zxf Python-3.11.4.tgz
        cd Python-3.11.4
        espeak "building python"
        ./configure --enable-optimizations
        eatmydata make -j 4
        espeak "installing python"
        sudo eatmydata make altinstall
        cd ..
    fi    
    sudo python3.11 -m pip install --upgrade virtualenv || exit -1

    espeak "installing virtual environment"
    # Rebuilding this is pretty cheap, so just do it every time.
    rm -rf $VENV
    python3.11 -m virtualenv --system-site-packages $VENV || exit -1
    PYTHON=$VENV/bin/python3
    espeak "installing virtual environment dependencies"
    $PYTHON -m pip install --ignore-installed psutil flask Flask-WTF pyalsaaudio pydub pyaudio pyyaml scipy dbus-python==1.2.18 || exit -1
    #Sometimes pygame tries to install without a whl, and fails (like 2.4.0) this
    #checks that only correct versions will install
    $PYTHON -m pip install --ignore-installed --only-binary ":all:" pygame || exit -1

    espeak "downloading PS move API"
    #install psmoveapi (currently adangert's for opencv 3 support)
    rm -rf psmoveapi
    git clone --recursive https://github.com/thp/psmoveapi.git 
    cd psmoveapi
    git checkout 8a1f8d035e9c82c5c134d848d9fbb4dd37a34b58

    espeak "compiling P S move A.P.I. components"
    mkdir build
    cd build
    cmake .. \
        -DPSMOVE_BUILD_CSHARP_BINDINGS:BOOL=OFF \
        -DPSMOVE_BUILD_EXAMPLES:BOOL=OFF \
        -DPSMOVE_BUILD_JAVA_BINDINGS:BOOL=OFF \
        -DPSMOVE_BUILD_OPENGL_EXAMPLES:BOOL=OFF \
        -DPSMOVE_BUILD_PROCESSING_BINDINGS:BOOL=OFF \
        -DPSMOVE_BUILD_TESTS:BOOL=OFF \
        -DPSMOVE_BUILD_TRACKER:BOOL=OFF \
        -DPSMOVE_USE_PSEYE:BOOL=OFF
    make -j4

    espeak "configuring system"
    #change the supervisord directory to our own homename
    #this replaces pi default username in joust.conf,
    sed -i -e "s/pi/$HOMENAME/g" $HOMEDIR/JoustMania/conf/supervisor/conf.d/joust.conf
    
    
    #installs custom supervisor script for running joustmania on startup
    sudo cp -r $HOMEDIR/JoustMania/conf/supervisor/ /etc/
    #force dmix systemwide
    sudo cp $HOMEDIR/JoustMania/conf/asound.conf /etc/
    
    #Use amixer to set sound output to 100%
    amixer sset ACODEC,0 100%
    sudo alsactl store
    
    #removed -disable_internal_bt as there is no internal bluetooth on AML-S905X-CC

    uname2="$(stat --format '%U' $HOMEDIR'/JoustMania/setup.sh')"
    uname3="$(stat --format '%U' $HOMEDIR'/JoustMania/piparty.py')"
    if [ "${uname2}" = "root" ] || [ "${uname3}" = "root" ] ; then
        sudo chown -R $HOMENAME:$HOMENAME $HOMEDIR/JoustMania/
        sudo git config --global --add safe.directory $HOMEDIR/JoustMania
        echo "directory and git permisions updated"
    else
        git config --global --add safe.directory $HOMEDIR/JoustMania
        echo "git permissions updated"
    fi
    
    echo "joustmania successfully updated, now rebooting"
    espeak "joustmania successfully updated, now rebooting"
    # Pause a second before rebooting so we can see all the output from this script.
    (sleep 2; sudo reboot) &
}

setup $1 2>&1 | tee setup.log
