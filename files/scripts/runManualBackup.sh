#!/usr/bin/env bash

wanted_date=$1
repo_name=$2
echo ${wanted_date}
echo $(date +'%d-%m-%Y-%H-%M')
if [[ $(date +'%d-%m-%Y-%H-%M') == ${wanted_date} ]]
then
    /usr/local/bin/backup.sh ${repo_name}
fi

