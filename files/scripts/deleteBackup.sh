backup_dir=$1
repository_name=$2
backups_max_count=$3
backup_days_max_count=$4

echo "Number of dirs: $(ls $backup_dir | grep $repository_name | wc -w) in $backup_dir"

if [ ! -z $backup_days_max_count ] && [ ! -z $(find $backup_dir -maxdepth 1 -mindepth 1 -type d -mtime +$backup_days_max_count -name "$repository_name*") ]
then
  echo "Removing backups $(find ${backup_dir} -maxdepth 1 -mindepth 1 -type d -mtime +${backup_days_max_count} -name "$repository_name*")"
  find ${backup_dir} -maxdepth 1 -mindepth 1 -type d -mtime +${backup_days_max_count} -name "$repository_name*" -exec rm -rf {} \;
  echo "Successfully removed old backups for repository $repository_name"
fi

if [ ! -z ${backups_max_count} ]
then
  while [ $( ls ${backup_dir} | wc -w)  -gt ${backups_max_count} ]
  do
    toDel=$( find  ${backup_dir} -maxdepth 1 -mindepth 1 -type d -name "$repository_name*" -exec stat -c '%X %n' {} \; | sort -nr | tail -n 1 | cut -d ' ' -f2 )
    echo "Removing ${toDel}"
    rm -rf "${toDel}"
  done
fi
