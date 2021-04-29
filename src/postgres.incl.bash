function run_postgres_tmp() {  
  if [ $UID = 0 ]; then
    su postgres -c 'pg_tmp -w 5 -t -p 15432'
  else
    pg_tmp -w 5 -t -p 15432
  fi
}
