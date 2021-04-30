function run_postgres_tmp() {  
  if [ $UID = 0 ]; then
    su postgres -c 'pg_tmp -w 5'
  else
    pg_tmp -w 5
  fi
}
