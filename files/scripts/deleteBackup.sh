#!/bin/bash
backup_dir=$1
while [ $(ls -l ${backup_dir} | wc -l) -gt 5 ]
do
	toDel=$(find ${backup_dir} -maxdepth 1 -type d -printf "%T@ %p \n" | sort -n | tail -n 2 | head -n 1 | cut -d ' ' -f2)
	echo "removing ${toDel}"
	rm -rf ${toDel}
done

