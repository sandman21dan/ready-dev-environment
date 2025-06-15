"""
This script reads a comma-separated string of camelCase words from STDIN,
converts each word to snake_case, and then prints the comma-separated
snake_case words to STDOUT.
"""

import sys
import re

def camel_to_snake(name):
    """
    Converts a camelCase string to snake_case.
    Handles common cases, including numbers and sequences of uppercase letters.
    """
    # 1. Insert an underscore before any uppercase letter that is not at the beginning
    #    and is preceded by a lowercase letter or a digit.
    #    e.g., "myVariable" -> "my_Variable"
    #    "HTMLParser" -> "HTM_LParser" (this is handled in the next step)
    s1 = re.sub(r'(?<=[a-z0-9])([A-Z])', r'_\1', name)

    # 2. Insert an underscore before any uppercase letter that is followed by a lowercase letter
    #    and is preceded by another uppercase letter. This helps with acronyms.
    #    e.g., "HTMLParser" -> "HTML_Parser"
    #    "MyURLHandler" -> "My_URLHandler"
    s2 = re.sub(r'(?<=[A-Z])([A-Z][a-z])', r'_\1', s1)

    return s2.lower()

def main():
    """
    Reads a comma-separated string from STDIN, converts each part to snake_case,
    and prints the result.
    """
    try:
        # Read the entire line from standard input
        input_line = sys.stdin.readline().strip()

        if not input_line:
            # If the input is empty, print an empty line and exit
            print("")
            return

        # Split the input line by commas
        items = input_line.split(',')

        # Convert each item from camelCase to snake_case
        snake_case_items = [camel_to_snake(item) for item in items]

        # Join the converted items back with commas and print
        print(','.join(snake_case_items))

    except Exception as e:
        print(f"An error occurred: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
