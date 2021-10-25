#!/bin/bash

if [ -z "$1" ] ; then
   echo "prvi argument admin password"
   exit 1
fi
 
CMD="create user admin with password '$1';"
su postgres -c "psql -c \"$CMD\""

CMD="GRANT xtrole TO admin GRANTED BY postgres;"
su postgres -c "psql -c \"$CMD\""




