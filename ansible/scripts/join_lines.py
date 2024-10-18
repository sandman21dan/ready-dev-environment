#!/usr/bin/env python

import sys
import argparse

parser = argparse.ArgumentParser(description="Join lines with a specified delimiter.")
parser.add_argument("-d", "--delimiter", default=",", help='Delimiter to join lines (default: ",")')

args = parser.parse_args()
delimiter = args.delimiter
lines = []

for line in sys.stdin:
    clean_line = line.strip()
    if clean_line != "":
        lines.append(clean_line)

print(delimiter.join(lines))
