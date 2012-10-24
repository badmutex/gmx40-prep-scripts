#!/usr/bin/env python

import pdbformat

import argparse

def getopts():
    p = argparse.ArgumentParser()
    p.add_argument('-f', '--inpdb')
    p.add_argument('-o', '--outpdb')

    return p.parse_args()


def fix_pdb(inpath, outpath):
    with open(inpath) as fd:
        data = fd.readlines()

    i = 1
    while True:

        if not len(pdbformat.getAtomStr(data, i+1)):
            break

        atomStr0 = pdbformat.getAtomStr(data, i-1)
        atomStr1 = pdbformat.getAtomStr(data, i)
        atomStr2 = pdbformat.getAtomStr(data, i+1)

        if \
                atomStr1[0] == 'H' and atomStr1[-1] == '2' \
                and not atomStr0[0] == 'H' and atomStr2[0] == 'H' and atomStr2[-1] == '3':
            newStr1 = atomStr1[:-1] + '1'
            newStr2 = atomStr2[:-1] + '2'
            pdbformat.setAtomStr(data, i, newStr1)
            pdbformat.setAtomStr(data, i+1, newStr2)
            i += 2
            print 'Atom', pdbformat.getAtomNum(data, i), 'Residue', pdbformat.getResidueNum(data, i), pdbformat.getResidueName(data,i),  atomStr1, '->', newStr1
            print 'Atom', pdbformat.getAtomNum(data, i+1), 'Residue', pdbformat.getResidueNum(data, i+1), pdbformat.getResidueName(data,i),  atomStr2, '->', newStr2

        else:
            i += 1


    with open(outpath, 'w') as fd:
        fd.write(''.join(data))



if __name__ == '__main__':
    opts = getopts()
    fix_pdb(opts.inpdb, opts.outpdb)
