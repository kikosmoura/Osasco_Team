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
	
        psql -f "populate_table_"$dir.sql --log-file=$LOGFILE

	if [ $? -ne 0 ]; then
   		echo "Erro na execucao do arquivo populate_table_"$dir.sql |& tee -a $LOGFILE
   		exit 1
        fi

else
	echo "Diretório não encontrado" |& tee -a $LOGFILE
	exit 1
fi

















