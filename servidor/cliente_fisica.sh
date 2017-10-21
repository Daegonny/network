#!/bin/bash

function build_frame {
    IP_DATA=`cat packet.txt | xxd -p | tr -d \\n`

    #Preamble e start frame delimiter em hexa
    PREAMBLE='AAAAAAAAAAAAAAAB'

    #Ethertype em hexa
    ETHERTYPE='0800'

    SRC_IP=$1
    echo "IP de Origem: $SRC_IP"

    DST_IP=$2
    echo "IP de Destino: $DST_IP"

    #Pegar o MAC da ORIGEM
    SRC_MAC=`ifconfig | sed -n '/^en.*HWaddr/s/.*addr.\([^ ]*\) .*/\1/p'`

    #Se não encontrar o MAC de origem
    if [ -z "$SRC_MAC" ]; then
        SRC_MAC="00:00:00:00:00:00"
    fi

    echo "MAC da Origem: $SRC_MAC"


    if [ "$SRC_IP" == "$DST_IP" ]; then
    	DST_MAC=$SRC_MAC
    else
    	#Ping para poder fazer o ARP
	    ping -c 1 $DST_IP &>/dev/null
	    DST_MAC=`arp $DST_IP | grep -E -o -e "([A-Za-z0-9]{2}:?){6}"`
	fi

    #Se não encontrar o MAC de destino
    if [ -z "$DST_MAC" ]; then
        DST_MAC="00:00:00:00:00:00"
    fi

    echo "MAC do Destino: $DST_MAC"

    #Remover os ':' dos endreços físicos
    SRC_MAC=`echo $SRC_MAC | sed "s/://g"`
    DST_MAC=`echo $DST_MAC | sed "s/://g"`

    #Montar o quadro Ethernet
    echo -n "${PREAMBLE}${DST_MAC}${SRC_MAC}${ETHERTYPE}${IP_DATA}" > frame_e.hex

    #Transfroma o quadro de hexa textual para binário
    xxd -r -p frame_e.hex > frame_e.dat

    #Calcula o CRC e adiciona no final do quadro
    crc32 frame_e.dat | xxd -r -p >> frame_e.dat

    #Transforma o quadro de binário para binário textual
    xxd -b frame_e.dat | cut -d" " -f 2-7 | sed "s/ //g" > frame_e.txt

    rm frame_e.hex &> /dev/null
    rm frame_e.dat &> /dev/null
}

#Porta da camada de rede do cliente
NET_PORT=`echo -n $1`

#Informações da Entidade Par
SERVER_IP=`echo -n $2`
SERVER_PORT=`echo -n $3`

#Se não informar a porta
if [ -z "$NET_PORT" ]; then
    echo "A porta da camada de rede deve ser informada"
    exit
fi

#Se não informar o SERVER_IP
if [ -z "$SERVER_IP" ]; then
    echo "O IP do servidor deve ser informado"
    exit
fi

#Se não informar o SERVER_PORT
if [ -z "$SERVER_PORT" ]; then
    echo "A porta do servidor deve ser informada"
    exit
fi

FILE=packet.txt

while true; do
    #Aguarda conexão da camada superior
    #echo "Esperando pacote IP..."
    nc -l $NET_PORT > packet.txt


    if [ -e "$FILE" ]; then
	    echo "Montando o frame..."
	    build_frame "192.168.15.7" "192.168.15.18"

	    #Exibe o pacote IP no formato HEX Dump
	    echo "Enviando o pacote IP..."
        #cat packet.txt
	    #xxd packet.txt

	    while true; do
	        #Envia o quadro Ethernet no formato binário textual para o servidor da camada física
	        nc $SERVER_IP $SERVER_PORT < frame_e.txt

	        if [ $? -eq 0 ]; then
	            break;
	        fi

	        echo -n "."
	        sleep 1
	    done

	    rm frame_e.txt &> /dev/null
	    rm packet.txt &> /dev/null
	fi
	sleep 2
done
