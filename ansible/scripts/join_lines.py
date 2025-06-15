"""
This script reads lines from STDIN, strips leading/trailing whitespace,
filters out empty lines, and then joins the remaining lines into a
single string using a specified delimiter.
"""
import sys
import argparse

def main():
    """
    Parses arguments, reads lines from STDIN, joins them with a delimiter,
    and prints the result.
    """
    parser = argparse.ArgumentParser(description="Join lines from STDIN with a specified delimiter.")
    parser.add_argument("-d", "--delimiter", default=",", help='Delimiter to join lines (default: ",")')

    args = parser.parse_args()
    delimiter = args.delimiter
    lines = []

    for line in sys.stdin:
        clean_line = line.strip()
        if clean_line:
            lines.append(clean_line)

    print(delimiter.join(lines))

if __name__ == "__main__":
    main()
