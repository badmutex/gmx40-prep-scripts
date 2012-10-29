#!/usr/bin/env python

import pdbformat

import argparse

def getopts():
    p = argparse.ArgumentParser()
    p.add_argument('-i', '--infile')
    p.add_argument('-o', '--outfile')

    return p.parse_args()

def remove_hydrogens(data):
    """
    data :: [[str]]
    -> [[str]]
    """

    newdata = []
    i = 0
    while i < len(data):

        atomStr = pdbformat.getAtomStr(data, i)

        if not atomStr: break

        if 'H' not in atomStr:
            newdata.append( data[i] )
        else:
            print 'Discarding line', repr(data[i])

        i += 1

    return newdata


if __name__ == '__main__':
    opts = getopts()
    with open(opts.infile) as fd:
        data = fd.readlines()
    newdata = remove_hydrogens(data)
    with open(opts.outfile, 'w') as fd:
        fd.write(''.join(newdata))
