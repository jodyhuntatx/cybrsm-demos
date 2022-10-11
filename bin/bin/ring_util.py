#!/usr/bin/env python

# Set Summon variable in keyring

import os
import sys

def write_and_flush(pipe, message):
    pipe.write(message)
    pipe.flush()

try:
    import keyring
except ImportError:
    write_and_flush(sys.stderr, '"keyring" library missing, run "pip install keyring"\n')
    sys.exit(1)

if __name__ == '__main__':
    if len(sys.argv) < 2:
        write_and_flush(sys.stderr, 'Usage: ring_util.py [ get | set | list ] <variable-name> [ <value> ].\n')
        sys.exit(1)

    command = sys.argv[1]
    if command == 'get':
	varname = sys.argv[2]
	value = keyring.get_password(
          os.environ.get('SUMMON_KEYRING_SERVICE', 'summon'),
          varname
        )
    elif command == 'set':
	varname = sys.argv[2]
	varvalue = sys.argv[3]
	keyring.set_password(
          os.environ.get('SUMMON_KEYRING_SERVICE', 'summon'),
          varname,
	  varvalue
        )
    elif command == 'list':
        write_and_flush(sys.stderr, 'list\n')
    else:
        write_and_flush(sys.stderr, 'Usage: ring_util.py [ get | set | list ] <variable-name> [ <value> ].\n')
        sys.exit(1)
