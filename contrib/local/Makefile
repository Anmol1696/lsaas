all: docker-clean clean setup start

setup:
	/bin/bash setup.sh

clean:
	rm -rf ~/.wasmd/keyring-test ~/.persistenceCore/keyring-test

###############################################################################
###                              Test commands                              ###
###############################################################################

run-osmosisd:
	/bin/bash contract-osmosisd.sh

run-persistencecore:
	/bin/bash contract-persistencecore.sh
