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

        psql -f "create_table_"$dir.sql --log-file=$LOGFILE
     #   psql -c "GRANT ALL ON "$schema.$tab" TO demanda_desmatamento" --log-file=$LOGFILE

	if [ $? -ne 0 ]; then
   		echo "Erro na execução do arquivo create_table_"$FILE.sql |& tee -a $LOGFILE
   		exit 1
    fi

else
	echo "Diretório não encontrado" |& tee -a $LOGFILE
	exit 1
fi

















