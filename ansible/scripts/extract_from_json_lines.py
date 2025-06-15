import argparse
import json
import sys

def extract_field_from_json_lines(field_name):
    """
    Reads JSON Lines from stdin, extracts a specified field, and prints its value.

    Args:
        field_name (str): The name of the field to extract from each JSON object.
    """
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue  # Skip empty lines

        try:
            data = json.loads(line)
            if field_name in data:
                # Ensure we handle various data types for the field's value
                value = data[field_name]
                if isinstance(value, (dict, list)):
                    # For complex types, print their JSON representation
                    print(json.dumps(value))
                else:
                    print(value)
        except json.JSONDecodeError:
            # Skip lines that are not valid JSON
            # You could add a warning here if needed, e.g.,
            # print(f"Warning: Skipping invalid JSON line: {line}", file=sys.stderr)
            continue
        except KeyError:
            # Skip lines where the field is not found
            continue

def main():
    """
    Main function to parse arguments and initiate processing.
    """
    parser = argparse.ArgumentParser(
        description="Extracts a specific field from JSON Lines input.",
        epilog="Example: cat data.jsonl | python script_name.py --field 'user.name'"
    )
    parser.add_argument(
        "--field",
        required=True,
        help="The name of the field to extract from the JSON objects. "
             "For nested fields, use dot notation (e.g., 'user.id')."
    )

    args = parser.parse_args()

    # Handle nested fields if specified with dot notation
    field_parts = args.field.split('.')

    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue

        try:
            data = json.loads(line)
            current_value = data
            found = True
            for part in field_parts:
                if isinstance(current_value, dict) and part in current_value:
                    current_value = current_value[part]
                else:
                    found = False
                    break
            
            if found:
                if isinstance(current_value, (dict, list)):
                    print(json.dumps(current_value))
                else:
                    print(current_value)

        except json.JSONDecodeError:
            # Silently skip invalid JSON lines
            pass
        # KeyError is implicitly handled by the 'found' flag logic for nested keys

if __name__ == "__main__":
    main()
