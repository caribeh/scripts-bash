#!/bin/bash
export OUTPUT_FILE=$3.log
export OPTION=$1

#Verificar ser o sshpass esta instalado
verify_dependencys() {
    if command -v sshpass &> /dev/null; then
        echo "$(date +'%Y/%m/%d - %H:%M:%S') - sshpass package is installed."
    else
        apt install -y sshpass
    fi
}

help(){
    echo 'usage: verifyback.sh [-l|-d|-h]
        -l filename outputfile   Take server to use from a file. This file can have multiple servers, one per line
        -s serverIP outputfile   Test one given server
        -a IP outputfile         Test all network ips (Write -a 127.0.0.0 for example, to test 127.0.0.1 until 127.0.0.255)
        -h outputfile            This Help menu'
}

back_verify() {
    echo ""
    echo "$(date +'%Y/%m/%d - %H:%M:%S') - Servidor $1: "
    if command -v xz &> /dev/null; then
        echo "$(date +'%Y/%m/%d - %H:%M:%S') - xz-utils package is installed."
        xz_version=$(xz --version | grep "xz (XZ Utils)")
        echo "$(date +'%Y/%m/%d - %H:%M:%S') - xz version: $xz_version."
        if [[ "$xz_version" =~ 5\.6\.[01] ]]; then
            echo "$(date +'%Y/%m/%d - %H:%M:%S') - System is vulnerable to CVE-2024-3094 (xz backdoor)."
        else
            echo "$(date +'%Y/%m/%d - %H:%M:%S') - System is not vulnerable to CVE-2024-3094 (xz backdoor)."
            echo ""
        fi
    else
        echo "$(date +'%Y/%m/%d - %H:%M:%S') - xz-utils package is not installed. System is not vulnerable to CVE-2024-3094 (xz backdoor)."
        echo ""
        exit 1
    fi

}

pega_senha(){
    echo "Digite a senha de acesso aos servidores"
    read -s PASS
    export PASS
}

exec_ssh(){
    sshpass -p$PASS ssh root@$SERVER -o StrictHostKeyChecking=no "$(typeset -f back_verify);back_verify $SERVER"  >> $OUTPUT_FILE 2> /dev/null
    if [ $? -ne 0 ]; then
        sshpass -p$PASS ssh infra@$SERVER -o StrictHostKeyChecking=no "$(typeset -f back_verify);back_verify $SERVER" >> $OUTPUT_FILE 2> /dev/null
        if [ $? -ne 0 ]; then
            echo "$(date +'%Y/%m/%d - %H:%M:%S') - $SERVER nao e um servidor Linux acessivel." >> $OUTPUT_FILE 
        fi
    fi
}

test_so(){
    export IP=$(echo $1|cut -d. -f1-3)
    for i in {1..255};do
        export SERVER=$IP.$i
        ttl=$(ping -c1 -w1 $SERVER | grep -o 'ttl=[0-9][0-9]*'|cut -d = -f2)
        if [ -z $ttl ];then
            echo "$(date +'%Y/%m/%d - %H:%M:%S') - IP $SERVER nao esta em uso." >> $OUTPUT_FILE
        elif [ $ttl -eq 60 ] || [ $ttl -eq 61 ] || [ $ttl -eq 62 ] || [ $ttl -eq 63 ] || [ $ttl -eq 64 ]; then
            exec_ssh
        else
            echo "$(date +'%Y/%m/%d - %H:%M:%S') - $SERVER nao e um servidor Linux." >> $OUTPUT_FILE
        fi
    done
}

verify_dependencys
case $OPTION in
    -h)help ;;
    -l)export LIST=$2;pega_senha;for SERVER in $(cat $LIST);do exec_ssh;done ;;
    -s)export SERVER=$2;pega_senha;exec_ssh ;;
    -a)pega_senha;test_so $2 ;;
    *)help ;;
esac