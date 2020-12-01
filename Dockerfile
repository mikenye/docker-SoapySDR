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
    # Dependencies for rtl-sdr
    KEPT_PACKAGES+=(libusb-1.0-0) && \
    TEMP_PACKAGES+=(libusb-1.0-0-dev) && \
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
    curl -s https://raw.githubusercontent.com/mikenye/deploy-s6-overlay/master/deploy-s6-overlay.sh | sh

COPY rootfs/ /

ENTRYPOINT [ "/init" ]
