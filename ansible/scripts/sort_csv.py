import argparse
import csv
import sys
import os

def parse_sort_specs(cols_str):
    """Parses the --cols argument into a list of sorting specifications."""
    specs = []
    # Split by comma for multiple columns
    for part in cols_str.split(','):
        part = part.strip()
        if not part:
            continue

        tokens = part.split()
        col_def = tokens[0]
        direction = tokens[1].lower() if len(tokens) > 1 else 'asc'

        if direction not in ('asc', 'desc'):
            sys.exit(f"Error: Invalid sort direction '{direction}'. Use 'asc' or 'desc'.")

        reverse = (direction == 'desc')

        # Parse type hint if present (e.g., "age:int")
        if ':' in col_def:
            col_name, type_str = col_def.rsplit(':', 1)
            if type_str == 'int':
                type_func = int
            elif type_str == 'float':
                type_func = float
            elif type_str == 'str':
                type_func = str
            else:
                sys.exit(f"Error: Unsupported type '{type_str}'. Use 'int', 'float', or omit for string.")
        else:
            col_name = col_def
            type_func = str

        specs.append({
            'col_name': col_name,
            'type_func': type_func,
            'reverse': reverse,
            'type_name': type_func.__name__
        })
    return specs

def main():
    parser = argparse.ArgumentParser(description="Sort a CSV file by multiple columns.")
    parser.add_argument("--file", required=True, help="Path to the input CSV file")
    parser.add_argument("--header", action="store_true", help="Indicates if the CSV has a header row")
    parser.add_argument("--cols", required=True, help='Columns to sort by (e.g., "identifier asc, age:int desc")')
    parser.add_argument("--in-place", action="store_true", help="Overwrite the input file")
    parser.add_argument("--out", help="Path to output file. Defaults to stdout if not provided")

    args = parser.parse_args()
    specs = parse_sort_specs(args.cols)

    # 1. Read the CSV into memory
    try:
        with open(args.file, 'r', newline='') as f:
            reader = csv.reader(f)
            rows = list(reader)
    except FileNotFoundError:
        sys.exit(f"Error: File '{args.file}' not found.")

    if not rows:
        sys.exit("Error: The provided CSV file is empty.")

    # 2. Separate header and resolve column indices
    if args.header:
        header = rows[0]
        data = rows[1:]
        for spec in specs:
            if spec['col_name'] not in header:
                sys.exit(f"Error: Column '{spec['col_name']}' not found in the header.")
            spec['idx'] = header.index(spec['col_name'])
    else:
        header = None
        data = rows
        for spec in specs:
            try:
                idx = int(spec['col_name'])
            except ValueError:
                sys.exit(f"Error: Without --header, columns must be zero-indexed integers. Got '{spec['col_name']}'.")

            if data and (idx < 0 or idx >= len(data[0])):
                sys.exit(f"Error: Column index {idx} out of bounds.")
            spec['idx'] = idx

    # 3. Sort the data
    # We sort in reverse order of the specified columns to utilize Python's stable sort.
    # This guarantees that the first column specified has the highest sorting priority.
    for spec in reversed(specs):
        idx = spec['idx']
        type_func = spec['type_func']
        reverse = spec['reverse']
        col_name = spec['col_name']
        type_name = spec['type_name']

        def sort_key(row):
            val = row[idx]
            try:
                return type_func(val)
            except ValueError:
                print(f"Error: Could not parse value '{val}' as '{type_name}' in column '{col_name}'.", file=sys.stderr)
                sys.exit(1)

        data.sort(key=sort_key, reverse=reverse)

    # 4. Write the output
    out_file = None
    if args.in_place:
        out_file = args.file
    elif args.out:
        out_file = args.out

    # Recombine header and data
    output_rows = [header] + data if header else data

    if out_file:
        with open(out_file, 'w', newline='') as f:
            writer = csv.writer(f)
            writer.writerows(output_rows)
        print(f"Successfully sorted and saved to {out_file}")
    else:
        writer = csv.writer(sys.stdout)
        writer.writerows(output_rows)

if __name__ == "__main__":
    main()
