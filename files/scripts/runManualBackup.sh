#!/usr/bin/env bash

wanted_date=$(echo $1 | tr ' ' '-' | tr ':' '-' | tr '.' '-')
repo_name=$2
topology=$3
echo "Wanted date: ${wanted_date}"
echo "Current date: $(date +'%d-%m-%Y-%H-%M')"
if [[ $(date +'%d-%m-%Y-%H-%M') == ${wanted_date} ]]
then
    /usr/local/bin/backup.sh ${repo_name} ${topology}
fi

