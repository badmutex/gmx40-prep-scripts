#!/usr/bin/env python


import os
import argparse
import subprocess


def getopts():
    p = argparse.ArgumentParser()
    p.add_argument('-i', '--infile')
    p.add_argument('-o', '--outfile')
    p.add_argument('-a', '--alias', nargs=2, action='append')

    return p.parse_args()

if __name__ == '__main__':
    opts = getopts()
    with open(opts.infile) as fdi, open(opts.outfile, 'w') as fdo:
        data = fdi.read()
        for original, newval in opts.alias:
            data = data.replace(original, newval)
        fdo.write(data)
