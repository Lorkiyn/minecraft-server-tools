#!/bin/bash

# Install reqired packages
echo "Unzip will be installed..."
apt install unzip -y

echo "Screen will be installed..."
apt install screen -y

# Setup Java
IS_MINECRAFT_PRE_16=false
JAVA_8_URL="https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u312-b07/OpenJDK8U-jdk_x64_linux_hotspot_8u312b07.tar.gz"
JAVA_8_FILE="/tmp/jdk-8u311-b07.tar.gz"
JAVA_8_PATH_PARENT="/opt/java"
JAVA_8_PATH_BIN="$JAVA_8_PATH_PARENT/jdk8u312-b07/bin"
JAVA_8_PATH_BIN_JAVA="$JAVA_8_PATH_BIN/java"
JAVA_8_PATH_BIN_JAVAC="$JAVA_8_PATH_BIN/javac"

JAVA_17_NAME="openjdk-17-jre-headless"

read -p "Minecraft version 1.16 or lower [y/n]: " is_pre_input

function install_java_8 () {
    wget -O $JAVA_8_FILE $JAVA_8_URL
    mkdir $JAVA_8_PATH_PARENT
    tar -xf $JAVA_8_FILE -C $JAVA_8_PATH_PARENT

    update-alternatives --install /usr/bin/java java $JAVA_8_PATH_BIN_JAVA 1
    update-alternatives --install /usr/bin/javac javac $JAVA_8_PATH_BIN_JAVAC 1
}

function install_java_17 () {
    apt install $JAVA_17_NAME
}

if [ $is_pre_input == "y" ] || [ $is_pre_input == "Y" ]; then
    echo "Minecraft version is 1.16 or lower, Java 8u312-b07 will be installed..."
    IS_MINECRAFT_PRE_16=true;
    install_java_8
else
    echo "Minecraft version is 1.17 or higher, lates Java 17 will be installed..."
    install_java_17
fi

# Add User
USERNAME="minecraft"
useradd -m $USERNAME

# Install minecraft server
MODPACK_SERVER_LOCATION="/home/$USERNAME/server"
MODPACK_SERVER_LOCATION_TEMP="$MODPACK_SERVER_LOCATION/tmp"
MODPACK_FILE="$MODPACK_SERVER_LOCATION/modpack.zip"

function unpack() {
    MAX_DEPTH=5
    i=1
    while [[ !(-d "$MODPACK_SERVER_LOCATION_TEMP/mods") ]]
    do
        if [ $i -ge $MAX_DEPTH ]; then
            echo "Could not find mods folder in $MODPACK_SERVER_LOCATION after unpacking"
            exit
        fi

        mv $MODPACK_SERVER_LOCATION_TEMP/*/* $MODPACK_SERVER_LOCATION_TEMP

        ((i++))
    done
}

read -p "Curseforge server-modpack download link: " modpack_url
echo "Downloading and unpacking modpack archive..."
mkdir $MODPACK_SERVER_LOCATION
wget -O $MODPACK_FILE $modpack_url
unzip $MODPACK_FILE -d $MODPACK_SERVER_LOCATION_TEMP

unpack

mv $MODPACK_SERVER_LOCATION_TEMP/* $MODPACK_SERVER_LOCATION
rm -rd $MODPACK_SERVER_LOCATION_TEMP

echo "Writing eula..."
echo "eula=true" > "$MODPACK_SERVER_LOCATION/eula.txt"

echo "Updating permissions..."
chmod +x "$MODPACK_SERVER_LOCATION/start.sh"
chown -R $USERNAME:$USERNAME $MODPACK_SERVER_LOCATION

echo "script.sh found!"

# Setup systemd
SYSTEMD_FILE_URL="https://raw.githubusercontent.com/Lorkiyn/minecraft-server-tools/main/minecraft.service"
SYSTEMD_SERVICE="minecraft.service"
SYSTEMD_FILE_PATH="/etc/systemd/system/$SYSTEMD_SERVICE"

echo "Generating systemd service..."
wget -O $SYSTEMD_FILE_PATH $SYSTEMD_FILE_URL
systemctl daemon-reload

echo "Systemd service name is $SYSTEMD_SERVICE"

# Finish
echo "Successfully installed minecraft server in $MODPACK_SERVER_LOCATION"
