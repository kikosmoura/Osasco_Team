#!/bin/bash

. params.sh


# Varrer todo o array e chamar o script 02-ingestao_arquivos.sh que exporta os arquivos .shp para o PostGis
for i in ${!diretorios[@]};
do

  dir=${diretorios[$i]}
  schema=${schemas[$i]}
  tab=${tabs[$i]}

 # FILE=$schema"_"$tab
  LOGFILE=$dir".log"

  # Ingestão do arquivo
 sudo bash ./03-execucao_criacao_arquivos.sh $tab $schema $dir


done







