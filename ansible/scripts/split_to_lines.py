"""
This script reads a single string from STDIN, splits it into multiple
lines based on a specified delimiter, and prints each part on a new line
after stripping leading/trailing whitespace from it.
"""
import sys
import argparse

def main():
    """
    Parses arguments, reads a string from STDIN, splits it by a delimiter,
    and prints each part on a new line.
    """
    parser = argparse.ArgumentParser(description="Split STDIN into multiple lines using a specified delimiter.")
    parser.add_argument("-d", "--delimiter", default=",", help='Delimiter to split lines (default: ",")')

    args = parser.parse_args()
    delimiter = args.delimiter

    # Read all of STDIN into a single string
    input_string = sys.stdin.read().strip()

    if input_string:
        parts = input_string.split(delimiter)
        for part in parts:
            # Ensure that even if a part is empty after splitting, we don't print an empty line
            # unless the part itself was just whitespace before stripping.
            stripped_part = part.strip()
            print(stripped_part)

if __name__ == "__main__":
    main()
