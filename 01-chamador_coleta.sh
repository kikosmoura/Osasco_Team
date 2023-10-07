#!/bin/bash

. params.sh

logfile=coleta.log

# Varrer todo o array e chamar o script 02-ingestao_arquivos.sh que exporta os arquivos .shp para o PostGis
for i in ${!URLs[@]};
do

  url=${URLs[$i]}
  file=$(echo `echo $url | cut -f8 -d'/' | cut -f1 -d.`)

  wget $url -O $file".zip" -a $logfile

  #unzip $file -d "arq_"$file
  unzip $file -d "arq_"$file
  sudo chmod 777 "arq_"$file
  rm $file".zip"

if [ $? -ne 0 ]; then
   echo "Erro no download do arquivo" |& tee -a $logfile
   exit 1
fi


done







