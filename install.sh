#!/bin/bash

function install_udpmod {
    clear
    rm -rf $(pwd)/$0

    echo ""
    read -p "Ingresa tu dominio: " domain
    echo ""
    read -p "Ingresa el puerto: " port

    apt update -y
    apt upgrade -y
    apt install git -y

    git clone https://github.com/SparkerMoved/UDPMOD.git

    dir=$(pwd)

    OBFS=$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 8)

    interfas=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)

    sys=$(which sysctl)

    ip4t=$(which iptables)
    ip6t=$(which ip6tables)

    openssl genrsa -out ${dir}/UDPMOD/udpmod.ca.key 2048
    openssl req -new -x509 -days 3650 -key ${dir}/UDPMOD/udpmod.ca.key -subj "/C=CN/ST=GD/L=SZ/O=Udpmod, Inc./CN=Udpmod Root CA" -out ${dir}/UDPMOD/udpmod.ca.crt
    openssl req -newkey rsa:2048 -nodes -keyout ${dir}/UDPMOD/udpmod.server.key -subj "/C=CN/ST=GD/L=SZ/O=Udpmod, Inc./CN=${domain}" -out ${dir}/UDPMOD/udpmod.server.csr
    openssl x509 -req -extfile <(printf "subjectAltName=DNS:${domain},DNS:${domain}") -days 3650 -in ${dir}/UDPMOD/udpmod.server.csr -CA ${dir}/UDPMOD/udpmod.ca.crt -CAkey ${dir}/UDPMOD/udpmod.ca.key -CAcreateserial -out ${dir}/UDPMOD/udpmod.server.crt

    sed -i "s/setobfs/${OBFS}/" ${dir}/UDPMOD/config.json
    sed -i "s#instDir#${dir}#g" ${dir}/UDPMOD/config.json
    sed -i "s#instDir#${dir}#g" ${dir}/UDPMOD/udpmod.service
    sed -i "s#iptb#${interfas}#g" ${dir}/UDPMOD/udpmod.service
    sed -i "s#sysb#${sys}#g" ${dir}/UDPMOD/udpmod.service
    sed -i "s#ip4tbin#${ip4t}#g" ${dir}/UDPMOD/udpmod.service
    sed -i "s#ip6tbin#${ip6t}#g" ${dir}/UDPMOD/udpmod.service

    chmod +x ${dir}/UDPMOD/*

    install -Dm644 ${dir}/UDPMOD/udpmod.service /etc/systemd/system

    systemctl daemon-reload
    systemctl start udpmod
    systemctl enable udpmod

    clear
    echo ""
    echo "Dominio: ${domain}" >> ${dir}/UDPMOD/data
    echo "Obfs: ${OBFS}" > ${dir}/UDPMOD/data
    echo "PUERTO: ${port}" >> ${dir}/UDPMOD/data
    echo "rango de puertos: 10000:65000" >> ${dir}/UDPMOD/data
    cat ${dir}/UDPMOD/data
    echo ""
    read -p "Presiona Enter para volver al menú..."
}

function uninstall_udpmod {
    clear
    systemctl stop udpmod
    systemctl disable udpmod
    rm -f /etc/systemd/system/udpmod.service
    systemctl daemon-reload
    rm -rf $(pwd)/UDPMOD
    echo "UDPMOD desinstalado."
    read -p "Presiona Enter para volver al menú..."
}

function activate_udpmod {
    clear
    if systemctl is-active --quiet udpmod; then
        echo "UDPMOD ya está activo."
    else
        if [ ! -d "$(pwd)/UDPMOD" ]; then
            install_udpmod
        else
            systemctl start udpmod
            echo "UDPMOD activado."
        fi
    fi
    read -p "Presiona Enter para volver al menú..."
}

function check_installation {
    clear
    if systemctl is-active --quiet udpmod; then
        echo "UDPMOD está instalado y activo."
    else
        echo "UDPMOD no está activo."
    fi
    read -p "Presiona Enter para volver al menú..."
}

function change_port {
    clear
    read -p "Ingresa el nuevo puerto: " new_port
    sed -i "s/\"port\": [0-9]\+/$new_port/" $(pwd)/UDPMOD/config.json
    echo "El puerto ha sido cambiado a ${new_port}."
    echo "port: ${new_port}" > $(pwd)/UDPMOD/data
    systemctl restart udpmod
    echo "UDPMOD ha sido reiniciado con el nuevo puerto."
    read -p "Presiona Enter para volver al menú..."
}

function menu {
    clear
    echo "1. Instalar UDPMOD"
    echo "2. Desinstalar UDPMOD"
    echo "3. Activar UDPMOD"
    echo "4. Verificar instalación"
    echo "5. Cambiar puerto"
    echo "6. Salir"
    read -p "Elige una opción: " choice
    case $choice in
        1) install_udpmod ;;
        2) uninstall_udpmod ;;
        3) activate_udpmod ;;
        4) check_installation ;;
        5) change_port ;;
        6) exit 0 ;;
        *) echo "Opción no válida" ;;
    esac
}

while true; do
    menu
done