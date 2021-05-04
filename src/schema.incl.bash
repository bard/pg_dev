function fingerprint_schema() {
  python3 -c 'import sys; from pglast.parser import fingerprint; print(fingerprint(sys.stdin.read()))'
}
