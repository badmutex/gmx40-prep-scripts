#!/usr/bin/env bash

set -e

inputpdb=$1


./removeHydrogends.py -i $inputpdb -o 00-nohydrogens.pdb
./passThroughTleap.py -f 00-nohydrogens.pdb -o 01-tleap.pdb
sed -i '/^TER$/d' 01-tleap.pdb
./residueSubstitutions.py -i 01-tleap.pdb -o 02-subst.pdb \
	-a 'LYS     1' 'NLYP    1' \
	-a 'ALA     1' 'NALA    1' \
	-a ' LYS ' ' LYP '
./fixHydrogens.py -f 02-subst.pdb -o 03-fixed.pdb
pdb2gmx -f 03-fixed.pdb -ff amber03
