#!/usr/bin/env python3

import argparse
import datetime
import hashlib
import sys

def calculate_padding(minute_value, seed_append, max_padding):
    """
    Calculates the number of padding spaces based on minute and an appended seed.
    """
    full_seed = f"{minute_value}{seed_append}"

    # Calculate MD5 hash of the full seed
    # Using encode() to get bytes from string
    md5_hash = hashlib.md5(full_seed.encode('utf-8')).hexdigest()

    # Take the first 8 characters of the hash for conversion
    # This provides enough variation while keeping the number manageable
    hash_segment = md5_hash[:8]

    try:
        # Convert the hex segment to a decimal integer
        hash_decimal = int(hash_segment, 16)
    except ValueError:
        # Fallback if hash_segment somehow isn't valid hex (shouldn't happen with hexdigest)
        hash_decimal = 0

    # Calculate the number of spaces using modulo
    # max_padding + 1 ensures values from 0 to max_padding
    num_spaces = hash_decimal % (max_padding + 1)
    return num_spaces

def main():
    parser = argparse.ArgumentParser(
        description="Generate padding spaces based on minute and an optional seed."
    )
    parser.add_argument(
        "--minute",
        type=int,
        help="Override the current minute (0-59) for testing purposes."
    )
    parser.add_argument(
        "--seed-append",
        type=str,
        default="",
        help="A string to append to the minute seed, to vary output for multiple calls within the same minute."
    )
    # Define the maximum padding we want (0 to max_padding spaces)
    parser.add_argument(
        "--max-padding",
        type=int,
        default=4, # Default to 0-4 spaces
        help="Maximum number of spaces for padding (e.g., 4 for 0-4 spaces)."
    )

    args = parser.parse_args()

    # Get the minute value
    if args.minute is not None:
        if not (0 <= args.minute <= 59):
            print("Error: --minute value must be between 0 and 59.", file=sys.stderr)
            sys.exit(1)
        current_minute = args.minute
    else:
        current_minute = datetime.datetime.now().minute

    # Calculate the number of spaces
    spaces = calculate_padding(current_minute, args.seed_append, args.max_padding)

    # Print the spaces
    print(' ' * spaces, end='')

if __name__ == "__main__":
    main()
