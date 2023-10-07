#!/bin/bash

. params.sh

# Recebe os parametros
tab=$1
schema=$2
dir=$3

LOGFILE=$dir".log"


# Executa os comandos dentro do arquivo descompactado
cd $dir
if [ "$?" = "0" ]; then
	
	#Obtem o nome dos arquivos
	nome=$(echo `ls *.shp | cut -f1 -d.`)

        shp2pgsql -a -D -I -s 4326 -W utf-8 $nome $schema.$tab > "populate_table_"$dir.sql

	if [ $? -ne 0 ]; then
   		echo "Erro na criação do arquivo populate_table_"$dir.sql |& tee -a $LOGFILE
   		exit 1
    fi

else
	echo "Diretório não encontrado" |& tee -a $LOGFILE
	exit 1
fi

















