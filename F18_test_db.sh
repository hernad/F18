#!/bin/bash

createdb F18_test

psql -d F18_test <<EOF
ALTER USER postgres WITH PASSWORD  'Password12!';
\q
EOF

PGPASSWORD=Password12! psql -d F18_test <<EOF
select version();
\q
EOF