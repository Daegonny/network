#!/bin/bash

#Porta do servidor
SERVER_PORT=`echo -n $1`

#Porta da camada de rede
NET_PORT=`echo -n $2`

#TMQ
TMQ=`echo -n $3`


#Se não informar a porta
if [ -z "$SERVER_PORT" ]; then
    echo "A porta que será escutada deve ser informada"
    exit
fi

#Se não informar o NET_PORT
if [ -z "$NET_PORT" ]; then
    echo "A porta da camada de rede deve ser informada"
    exit
fi

#Se não informar o TMQ
if [ -z "$TMQ" ]; then
    echo "O TMQ deve ser informado (de 88-1542)"
    exit
fi

#Faixa de valores para o TMQ
if [ "$TMQ" -lt "88" ] || [ "$TMQ" -gt "1542" ]; then
    echo "O TMQ deve estar entre 88 e 1542"
    exit
fi

while true; do
    #Espera a conexão do cliente da camada física
    echo "Esperando conexão..."
    nc -l $SERVER_PORT > frame_r.txt

    #Armazena o pedido para verificar se é a mensagem de TMQ
    REQUEST=`cat frame_r.txt`

    #Só responde com o TMQ se a mensagem for exatamente "TMQ"
    if [ "$REQUEST" == "TMQ" ]; then
        echo "Repondendo com TMQ: $TMQ"
        echo -n "TMQ:$TMQ" > payload.bin
    else
        #Caso contrário considera que é um quadro Ethernet em formato binário textual
        echo "Recebendo Frame Ethernet..."

        #Separa o arquivo em dígitos hexa (4 bits)
        cat frame_r.txt | sed "s/\([0-9]\{4\}\)/\1\n/g" > frame_r.dat

        #Convertendo cada dígito hexa de binário textual para hexa textual
        rm frame_r.hex &> /dev/null
        while read line; do
            echo "obase=16; ibase=2; $line" | bc | tr -d \\n >> frame_r.hex
        done < frame_r.dat

        #Conversão de hexa textual para binário
        xxd -r -p frame_r.hex > frame_r.dat
        xxd -r -p frame_r.hex > frame_r.txt

        #Exibe o quadro Ethernet no formato HEX Dump e textual
        cat frame_r.hex
        printf "\n"
        printf "\n"
        cat frame_r.dat
        printf "\n"

        # sed '1 s/.\{,14\}//' frame_r.txt | sed `cat frame_r.txt | wc -l`'s/.\{,4\}//' > payload.txt
        sed "s/.\{44\}//" frame_r.hex | sed "s/.\{8\}$//" | xxd -r -p > payload.txt

        #sed "s/.\{44\}//" -> remove o cabeçalho (Preamble + MAC Dst + MAC Src + Ethertype = 22 bytes)
        #sed "s/.\{8\}$//" -> remove o CRC (4 bytes)
        cat frame_r.dat | xxd -p | tr -d \\n | sed "s/.\{44\}//" | sed "s/.\{8\}$//" > payload.hex


        #xxd -r -p payload.hex > payload.bin
        MESSAGE=`cat payload.txt`
    fi

    #Entrega o pacote IP (PAYLOAD do quadro Ethernet) para a camada superior
    #echo "Enviando para camada superior..."
    #todo : nc 127.0.0.1 $NET_PORT < payload.bin
    nc 127.0.0.1 $NET_PORT < payload.txt

    rm frame_r.txt &> /dev/null
    rm frame_r.dat &> /dev/null
    rm frame_r.hex &> /dev/null
    rm payload.hex &> /dev/null
    rm payload.txt &> /dev/null
    rm frame_r.txt &> /dev/null
done
