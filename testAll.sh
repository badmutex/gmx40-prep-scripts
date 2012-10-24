#!/usr/bin/env bash

set -e

for pdb in ../../startfiles/extended/hipin-*.pdb ../../startfiles/folded/hipin-*.pdb; do
	echo $pdb
	./prepare-gmx40.sh $pdb
	rm \#*
done

echo "SUCCESS!!"