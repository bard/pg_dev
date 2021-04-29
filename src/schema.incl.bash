function fingerprint_schema() {
  ruby -rpg_query -e 'puts PgQuery.fingerprint(STDIN.read)'
}
