import argparse
import secrets
import string
import sys

def generate_random_string(length, use_upper, use_lower, use_numeric):
    # Initialize the character pool
    characters = ""
    if use_upper:
        characters += string.ascii_uppercase
    if use_lower:
        characters += string.ascii_lowercase
    if use_numeric:
        characters += string.digits

    # Error handling if no character sets are selected
    if not characters:
        print("Error: You must include at least one character type (lowercase, uppercase, or numeric).", file=sys.stderr)
        sys.exit(1)

    # Generate the string using secrets for better randomness
    return ''.join(secrets.choice(characters) for _ in range(length))

def main():
    parser = argparse.ArgumentParser(description="Generate a random alphanumeric string.")

    # Argument definitions
    parser.add_argument("-L", "--length", type=int, default=6,
                        help="Length of the generated string (default: 6)")

    # Uppercase: Default False
    parser.add_argument("-u", "--uppercase", action="store_true", default=False,
                        help="Include uppercase characters (default: False)")

    # Lowercase: Default True.
    # We use 'store_false' on a 'no' flag to allow disabling it,
    # or just allow the user to toggle.
    parser.add_argument("-l", "--lowercase", action="store_true", default=True,
                        help="Include lowercase characters (default: True)")
    parser.add_argument("--no-lowercase", dest="lowercase", action="store_false",
                        help="Exclude lowercase characters")

    # Numeric: Default True
    parser.add_argument("-n", "--numeric", action="store_true", default=True,
                        help="Include numeric characters (default: True)")
    parser.add_argument("--no-numeric", dest="numeric", action="store_false",
                        help="Exclude numeric characters")

    args = parser.parse_args()

    result = generate_random_string(args.length, args.uppercase, args.lowercase, args.numeric)
    print(result)

if __name__ == "__main__":
    main()
