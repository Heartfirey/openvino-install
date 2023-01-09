if [ $# -eq 0 ];then

        echo "---------------------------------------------------------------------------"
        # OS Type
        echo "                    OS Type: $(uname -o)"
        # OS Release Version and Name
        echo "OS Release Version and Name: $(cat /etc/issue | head -n 1)"
        #Architecture
        echo "               Architecture: $(uname -m)"
        #Kernel Release
        echo "             Kernel Release: $(uname -r)"
        #hostname
        echo "                   hostname: $HOSTNAME"
        #Internal IP
        echo "                Internal IP: $(hostname -I)"
        #External IP
        echo "                External IP: $(curl -s ipecho.net/plain)"
        echo "---------------------------------------------------------------------------"

fi

# Detect user
if [ "$(whoami)" == "root" ]; then
    echo "[OK] Run script as root user."
else 
    echo "[FAILD] Please run this script as root user!"
    exit -1
fi

# Detect CMAKE
if ! type "cmake" >/dev/null 2>&1; then
    echo "[ERROR] CMAKE no detected!"
    if command -v apt > /dev/null 2>&1; then
        echo "[OK] Install CMAKE from apt"
        apt install -y cmake
    else
        echo "[OK] Install CMAKE from yum"
        yun install -y cmake
    fi
else
    echo "[OK] CMAKE environment detected."
fi

# Create install dir
dir="/home/$(whoami)/openvino-install"
if [ ! -d dir ]; then
    mkdir -p $dir
    echo "[OK] Creating install folder: $dir"
else 
    echo "[WARN] $dir has already exists!"
fi

# Goto folder
cd $dir
echo "[OK] Goto $dir"
# Download the lastest openvino toolkit
wget https://storage.openvinotoolkit.org/repositories/openvino/packages/2022.3/linux/l_openvino_toolkit_debian9_2022.3.0.9052.9752fafe8eb_armhf.tgz -O openvino_2022.3.0.tgz

target_dir="/opt/intel/openvino"

# Detect target dir
if [ ! -d target_dir ]; then
    mkdir -p $target_dir
    echo "[OK] Creating target folder: $target_dir"
else 
    echo "[WARN] $target_dir has already exists! Please delete it manually!"
    exit -1
fi

tar -xf openvino_2022.3.0.tgz --strip 1 -C /opt/intel/openvino
# Setup env_vars
source /opt/intel/openvino/setupvars.sh

echo "source /opt/intel/openvino/setupvars.sh" >> ~/.bashrc

echo "[OK] Openvino Toolkits has been installed."

echo "[INFO] Now configurate the USB device..."

sudo usermod -a -G users "$(whoami)"

echo "[INFO] Using USB Rule: <Intel Neural Compute Stick 2> (NCS)"

cat <<EOF > 97-myriad-usbboot.rules 
SUBSYSTEM=="usb", ATTRS{idProduct}=="2150", ATTRS{idVendor}=="03e7", GROUP="users", MODE="0666", ENV{ID_MM_DEVICE_IGNORE}="1"
SUBSYSTEM=="usb", ATTRS{idProduct}=="2485", ATTRS{idVendor}=="03e7", GROUP="users", MODE="0666", ENV{ID_MM_DEVICE_IGNORE}="1"
SUBSYSTEM=="usb", ATTRS{idProduct}=="f63b", ATTRS{idVendor}=="03e7", GROUP="users", MODE="0666", ENV{ID_MM_DEVICE_IGNORE}="1"
EOF

sudo cp 97-myriad-usbboot.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger
sudo ldconfig
rm 97-myriad-usbboot.rules

echo "[OK] Generating dev autoload rules."

sh /opt/intel/openvino/install_dependencies/install_NCS_udev_rules.sh

# clear
echo "[DONE] All actions has benn done."