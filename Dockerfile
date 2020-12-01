FROM debian:stable-slim

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -x && \
    TEMP_PACKAGES=() && \
    KEPT_PACKAGES=() && \
    # Dependencies for s6-overlay
    TEMP_PACKAGES+=(ca-certificates) && \
    TEMP_PACKAGES+=(curl) && \
    TEMP_PACKAGES+=(file) && \
    TEMP_PACKAGES+=(gnupg) && \
    # Dependencies for downloading/building
    TEMP_PACKAGES+=(autoconf) && \
    TEMP_PACKAGES+=(build-essential) && \
    TEMP_PACKAGES+=(ca-certificates) && \
    TEMP_PACKAGES+=(cmake) && \
    TEMP_PACKAGES+=(curl) && \
    TEMP_PACKAGES+=(git) && \
    # Dependencies for logging
    KEPT_PACKAGES+=(gawk) && \
    # Dependencies for USB-attached radios
    KEPT_PACKAGES+=(libusb-1.0-0) && \
    TEMP_PACKAGES+=(libusb-1.0-0-dev) && \
    # Dependencies for bladeRF
    KEPT_PACKAGES+=(libncurses5) && \
    TEMP_PACKAGES+=(libncurses5-dev) && \
    KEPT_PACKAGES+=(libtecla1) && \
    TEMP_PACKAGES+=(libtecla-dev) && \
    KEPT_PACKAGES+=(libedit2) && \
    TEMP_PACKAGES+=(libedit-dev) && \
    # Dependencies for hackrf
    KEPT_PACKAGES+=(libfftw3-3) && \
    TEMP_PACKAGES+=(libfftw3-dev) && \
    # Dependencies for PlutoSDR
    KEPT_PACKAGES+=(libiio0) && \
    TEMP_PACKAGES+=(libiio-dev) && \
    KEPT_PACKAGES+=(libad9361-0) && \
    TEMP_PACKAGES+=(libad9361-dev) && \
    # Dependencies for SoapyRemote
    KEPT_PACKAGES+=(avahi-daemon) && \
    TEMP_PACKAGES+=(libavahi-client-dev) && \
    KEPT_PACKAGES+=(libavahi-client3) && \
    TEMP_PACKAGES+=(libavahi-common-dev) && \
    KEPT_PACKAGES+=(libavahi-common3) && \
    KEPT_PACKAGES+=(libavahi-common-data) && \
    TEMP_PACKAGES+=(libavahi-core-dev) && \
    KEPT_PACKAGES+=(libavahi-core7) && \
    TEMP_PACKAGES+=(libdbus-1-dev) && \
    KEPT_PACKAGES+=(libdbus-1-3) && \
    # Install packages
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ${KEPT_PACKAGES[@]} \
        ${TEMP_PACKAGES[@]} \
        && \
    git config --global advice.detachedHead false && \
    # Deploy rtl-sdr
    git clone git://git.osmocom.org/rtl-sdr /src/rtl-sdr && \
    pushd /src/rtl-sdr && \
    mkdir -p /src/rtl-sdr/build && \
    pushd /src/rtl-sdr/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release && \
    make all && \
    make install && \
    popd && popd && \
    ldconfig && \
    # Deploy bladeRF
    git clone https://github.com/Nuand/bladeRF.git /src/bladeRF && \
    pushd /src/bladeRF && \
    BRANCH_BLADERF=$(git tag --sort="creatordate" | grep -P '^[\d\.]+$' | tail -1) && \
    git checkout "$BRANCH_BLADERF" && \
    mkdir -p /src/bladeRF/build && \
    pushd /src/bladeRF/build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local -DINSTALL_UDEV_RULES=ON ../ && \
    make all && \
    make install && \
    # Download bladeRF FPGA Images
    BLADERF_RBF_PATH="/usr/share/Nuand/bladeRF" && \
    mkdir -p "$BLADERF_RBF_PATH" && \
    curl -o "$BLADERF_RBF_PATH/hostedxA4.rbf" https://www.nuand.com/fpga/hostedxA4-latest.rbf && \
    curl -o "$BLADERF_RBF_PATH/hostedxA9.rbf" https://www.nuand.com/fpga/hostedxA9-latest.rbf && \
    curl -o "$BLADERF_RBF_PATH/hostedx40.rbf" https://www.nuand.com/fpga/hostedx40-latest.rbf && \
    curl -o "$BLADERF_RBF_PATH/hostedx115.rbf" https://www.nuand.com/fpga/hostedx115-latest.rbf && \
    curl -o "$BLADERF_RBF_PATH/adsbxA4.rbf" https://www.nuand.com/fpga/adsbxA4.rbf && \
    curl -o "$BLADERF_RBF_PATH/adsbxA9.rbf" https://www.nuand.com/fpga/adsbxA9.rbf && \
    curl -o "$BLADERF_RBF_PATH/adsbx40.rbf" https://www.nuand.com/fpga/adsbx40.rbf && \
    curl -o "$BLADERF_RBF_PATH/adsbx115.rbf" https://www.nuand.com/fpga/adsbx115.rbf && \
    # Deploy hackrf
    git clone https://github.com/mossmann/hackrf.git /src/hackrf && \
    pushd /src/hackrf && \
    BRANCH_HACKRF=$(git tag --sort="creatordate" | grep -P '^v[\d\.]+$' | tail -1) && \
    git checkout "$BRANCH_HACKRF" && \
    mkdir -p /src/hackrf/host/build && \
    pushd /src/hackrf/host/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release && \
    make all && \
    make install && \
    popd && popd && \
    ldconfig && \
    # Deploy airspy
    git clone https://github.com/airspy/airspyone_host.git /src/airspyone_host && \
    pushd /src/airspyone_host && \
    BRANCH_AIRSPYONE_HOST=$(git tag --sort="creatordate" | tail -1) && \
    git checkout "$BRANCH_AIRSPYONE_HOST" && \
    mkdir -p /src/airspyone_host/build && \
    pushd /src/airspyone_host/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release -DINSTALL_UDEV_RULES=ON && \
    make all && \
    make install && \
    popd && popd && \
    ldconfig && \
    # Deploy airspyhf
    git clone https://github.com/airspy/airspyhf.git /src/airspyhf && \
    pushd /src/airspyhf && \
    BRANCH_AIRSPYHF=$(git tag --sort="creatordate" | tail -1) && \
    git checkout "$BRANCH_AIRSPYHF" && \
    mkdir -p /src/airspyhf/build && \
    pushd /src/airspyhf/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release -DINSTALL_UDEV_RULES=ON && \
    make all && \
    make install && \
    popd && popd && \
    ldconfig && \
    # Deploy SoapySDR
    git clone https://github.com/pothosware/SoapySDR.git /src/SoapySDR && \
    pushd /src/SoapySDR && \
    BRANCH_SOAPYSDR=$(git tag --sort="creatordate" | tail -1) && \
    git checkout "$BRANCH_SOAPYSDR" && \
    mkdir -p /src/SoapySDR/build && \
    pushd /src/SoapySDR/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release && \
    make all && \
    make test && \
    make install && \
    popd && popd && \
    ldconfig && \
    # Deploy LimeSuite
    git clone https://github.com/myriadrf/LimeSuite.git /src/LimeSuite && \
    pushd /src/LimeSuite && \
    BRANCH_LIMESUITE=$(git tag --sort="creatordate" | tail -1) && \
    git checkout "$BRANCH_LIMESUITE" && \
    mkdir -p /src/LimeSuite/build && \
    pushd /src/LimeSuite/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release && \
    make all && \
    make install && \
    popd && popd && \
    ldconfig && \
    # Deploy SoapyRemote
    git clone https://github.com/pothosware/SoapyRemote.git /src/SoapyRemote && \
    pushd /src/SoapyRemote && \
    BRANCH_SOAPYREMOTE=$(git tag --sort="creatordate" | tail -1) && \
    git checkout "$BRANCH_SOAPYREMOTE" && \
    mkdir -p /src/SoapyRemote/build && \
    pushd /src/SoapyRemote/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release && \
    make all && \
    make install && \
    popd && popd && \
    ldconfig && \
    # Deploy SoapyRTLSDR
    git clone https://github.com/pothosware/SoapyRTLSDR.git /src/SoapyRTLSDR && \
    pushd /src/SoapyRTLSDR && \
    BRANCH_SOAPYRTLSDR=$(git tag --sort="creatordate" | tail -1) && \
    git checkout "$BRANCH_SOAPYRTLSDR" && \
    mkdir -p /src/SoapyRTLSDR/build && \
    pushd /src/SoapyRTLSDR/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release && \
    make all && \
    make install && \
    popd && popd && \
    ldconfig && \
    # Deploy SoapyBladeRF
    git clone https://github.com/pothosware/SoapyBladeRF.git /src/SoapyBladeRF && \
    pushd /src/SoapyBladeRF && \
    BRANCH_SOAPYBLADERF=$(git tag --sort="creatordate" | tail -1) && \
    git checkout "$BRANCH_SOAPYBLADERF" && \
    mkdir -p /src/SoapyBladeRF/build && \
    pushd /src/SoapyBladeRF/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release && \
    make all && \
    make install && \
    popd && popd && \
    ldconfig && \
    # Deploy SoapyHackRF
    git clone https://github.com/pothosware/SoapyHackRF.git /src/SoapyHackRF && \
    pushd /src/SoapyHackRF && \
    BRANCH_SOAPYHACKRF=$(git tag --sort="creatordate" | tail -1) && \
    git checkout "$BRANCH_SOAPYHACKRF" && \
    mkdir -p /src/SoapyHackRF/build && \
    pushd /src/SoapyHackRF/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release && \
    make all && \
    make install && \
    popd && popd && \
    ldconfig && \
    # Deploy SoapyPlutoSDR
    git clone https://github.com/pothosware/SoapyPlutoSDR.git /src/SoapyPlutoSDR && \
    pushd /src/SoapyPlutoSDR && \
    BRANCH_SOAPYPLUTOSDR=$(git tag --sort="creatordate" | tail -1) && \
    git checkout "$BRANCH_SOAPYPLUTOSDR" && \
    mkdir -p /src/SoapyPlutoSDR/build && \
    pushd /src/SoapyPlutoSDR/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release && \
    make all && \
    make install && \
    popd && popd && \
    ldconfig && \
    # Deplot SoapyAirspy
    git clone https://github.com/pothosware/SoapyAirspy.git /src/SoapyAirspy && \
    pushd /src/SoapyAirspy && \
    BRANCH_SOAPYAIRSPY=$(git tag --sort="creatordate" | tail -1) && \
    git checkout "$BRANCH_SOAPYAIRSPY" && \
    mkdir -p /src/SoapyAirspy/build && \
    pushd /src/SoapyAirspy/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release && \
    make all && \
    make install && \
    popd && popd && \
    ldconfig && \
    # Deploy SoapyAirspyHF
    git clone https://github.com/pothosware/SoapyAirspyHF.git /src/SoapyAirspyHF && \
    pushd /src/SoapyAirspyHF && \
    BRANCH_SOAPYAIRSPYHF=$(git tag --sort="creatordate" | tail -1) && \
    git checkout "$BRANCH_SOAPYAIRSPYHF" && \
    mkdir -p /src/SoapyAirspyHF/build && \
    pushd /src/SoapyAirspyHF/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release && \
    make all && \
    make install && \
    popd && popd && \
    ldconfig && \
    # Deploy SoapyMultiSDR
    git clone https://github.com/pothosware/SoapyMultiSDR.git /src/SoapyMultiSDR && \
    pushd /src/SoapyMultiSDR && \
    mkdir -p /src/SoapyMultiSDR/build && \
    pushd /src/SoapyMultiSDR/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release && \
    make all && \
    make test && \
    make install && \
    popd && popd && \
    ldconfig && \
    # Configure dbus
    mkdir -p /var/run/dbus && \
    # Deploy s6-overlay
    curl -s https://raw.githubusercontent.com/mikenye/deploy-s6-overlay/master/deploy-s6-overlay.sh | sh && \
    # Clean-up
    apt-get remove -y ${TEMP_PACKAGES[@]} && \
    apt-get autoremove -y && \
    rm -rf /src/* /tmp/* /var/lib/apt/lists/* && \
    # Test
    SoapySDRUtil --info

COPY rootfs/ /

ENTRYPOINT [ "/init" ]
