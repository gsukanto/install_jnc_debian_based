#!/bin/bash
# stupid shell script
# for debian based with apt support and have internet connection only

BEGIN_CERTIFICATE='-----BEGIN CERTIFICATE-----'
END_CERTIFICATE='-----END CERTIFICATE-----'
SPLITTER=' ========== '
WORKDIR=/tmp/vpn_workdir
JUNIPER_DIR=~/.juniper_networks/network_connect

usage() {
    echo "\n\n"
    echo 'Usage: ./install_vpn.sh -n <connection name> -u <vpn username> -a <nc_linux_app url> -r <vpn realm (optional)> -h <host ip>  -j <jnc url (optional)>'
    echo "\n\n"
    exit 0
}

rm_workdir() {
    rm -rf $WORKDIR
    mkdir $WORKDIR
    cd $WORKDIR    
}

install_depedencies() {
    echo $SPLITTER 'installing depedencies...'  $SPLITTER
    sudo apt-get install libc6-i386 lib32z1 unzip wget -f 
}

download_ncLinuxApp() {
    echo $SPLITTER 'geting the jar file' $SPLITTER
    echo $NCLINUXAPP_URL
    wget $NCLINUXAPP_URL
}

extract_ncLinuxApp() {
    echo $SPLITTER 'extracting the jar file'  $SPLITTER
    rm -rf $JUNIPER_DIR
    mkdir -p $JUNIPER_DIR
    unzip ncLinuxApp.jar -d $JUNIPER_DIR
    chmod 6711 $JUNIPER_DIR/ncsvc
    chmod 744 $JUNIPER_DIR/ncdiag
}

create_certificate() {
    echo $SPLITTER  'getting certificate' $SPLITTER
    cd $JUNIPER_DIR
    sh getx509certificate.sh $HOST_IP $NAME.der
    cp out.txt cert.txt
    openssl x509 -in cert.txt -outform der -out $NAME.der
    echo $SPLITTER 'get certificate is expected to be failed :p' $SPLITTER
    echo 'generate the cert and der file from failed get certificate'
    sed -n "/$BEGIN_CERTIFICATE/,/$END_CERTIFICATE/p" out.txt > $1.cert
}

install_jnc() {
    echo $SPLITTER 'installing jnc' $SPLITTER
    wget $JNC_URL
    chmod a+x jnc
    mv jnc /usr/local/bin
}

make_jnc_conf() {
    echo ''
    mkdir -p ~/.juniper_networks/network_connect/config
    echo "host=$HOST_IP
    user=$USER
    realm=$REALM
    cafile=/$HOME/.juniper_networks/network_connect/$NAME.cert
    certfile=$HOME/.juniper_networks/network_connect/$NAME.der" >> ~/.juniper_networks/network_connect/config/$NAME.conf    
}

echo_finished() {
    echo $SPLITTER$SPLITTER 'Finish' $SPLITTER$SPLITTER
    echo "\n\n"
    echo "Vpn start: jnc --nox $NAME"
    echo "Vpn stop: jnc stop"
    echo "\n\n"
}

main() {
    rm_workdir
    install_depedencies
    download_ncLinuxApp
    extract_ncLinuxApp
    create_certificate
    install_jnc
    make_jnc_conf
    echo_finished
}

is_sudo() {
    if [ "$(id -u)" != "0" ]; then
        echo "Need to be sudo.\nPlease try again as sudo."
        exit 0
    fi    
}

is_sudo

REALM='Karyawan'
JNC_URL='https://www.scc.kit.edu/scc/net/juniper-vpn/linux/jnc'

while getopts "n:u:r:a:h:j:" opt; do
   case "$opt" in
        n )  NAME=$OPTARG ;;
        u )  USER=$OPTARG ;;
        r )  REALM=$OPTARG ;;
        h )  HOST_IP=$OPTARG;;
        a )  NCLINUXAPP_URL=$OPTARG ;;
        j )  JNC_URL=$OPTARG ;;
       \?)  usage ;;
   esac
done

if !( [ $NAME ] && [ $USER ] && [ $NCLINUXAPP_URL ] && [$HOST_IP] ) ; then
    echo '\nMissing name or user or ncLinuxApp url or host param.'
    echo "Name: $NAME\nUser: $USER\nNcLinuxApp url: $NCLINUXAPP_URL\n$HOST_IP"
    usage
    exit 0
fi

echo $SPLITTER "initializing for $NAME vpn" $SPLITTER

main 
