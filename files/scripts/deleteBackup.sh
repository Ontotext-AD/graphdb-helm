backup_dir=$1
backups_max_count=$2

echo "num of dirs: $(ls ${backup_dir} | wc -w) in ${backup_dir}"

while [ $( ls ${backup_dir} | wc -w)  -gt ${backups_max_count} ]
do
	toDel=$( find  ${backup_dir} -maxdepth 1 -mindepth 1 -type d -exec stat -c '%X %n' {} \; | sort -nr | tail -n 1 | cut -d ' ' -f2 )
	echo "removing ${toDel}"
	rm -rf "${toDel}"
done

