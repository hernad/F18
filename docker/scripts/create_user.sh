#!/bin/bash

CMD="create user bjasko with password 'bjasko';"
su postgres -c "psql -c \"$CMD\""

CMD="GRANT xtrole TO bjasko GRANTED BY postgres;"
su postgres -c "psql -c \"$CMD\""


#cat f18_prazno.sql |   docker exec --interactive postgresql  psql  -U postgres -d postgres  -

