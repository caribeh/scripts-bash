#!/bin/bash

for i in {1..255}; do
        ping -q -A -W 1 -c 1 $1.$i 1>/dev/nul;
        if [ $? -eq 0 ]; then
                echo -e "\e[1;32m $1.$i FUNCIONA! \e[0m";
        else
                echo -e "\e[1;31m $1.$i NÃO FUNCIONA! \e[0m";
        fi
done