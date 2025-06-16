"""
This script calculates and displays various differences between an initial
and a new value provided as command-line arguments.

It computes:
1. The decimal difference (new_value - initial_value).
2. The new value as a percentage of the initial value ((new_value / initial_value) * 100).
3. The percentage difference (((new_value - initial_value) / initial_value) * 100).

Handles division by zero gracefully.
"""
import argparse

def calculate_and_print_differences(initial_value, new_value):
    """
    Calculates and prints the specified differences and percentages.

    Args:
        initial_value (float): The starting value.
        new_value (float): The subsequent value.
    """
    label_initial = "Initial Value"
    label_new = "New Value"
    label_decimal_diff = "Decimal Difference"
    label_percent_of_initial = "New Value as Percentage of Initial"
    label_percentage_diff = "Percentage Difference"

    # Determine max label length for alignment
    max_label_len = max(
        len(label_initial), len(label_new), len(label_decimal_diff),
        len(label_percent_of_initial), len(label_percentage_diff)
    )

    def print_stat(label, value_str):
        """Helper function to print a formatted statistic line."""
        print(f"{label:<{max_label_len}} : {value_str}")

    print_stat(label_initial, f"{initial_value:g}")
    print_stat(label_new, f"{new_value:g}")
    print("-" * (max_label_len + 3 + 20))  # Separator line

    # 1. Decimal difference
    decimal_diff = new_value - initial_value
    print_stat(label_decimal_diff, f"{decimal_diff:g}")

    # 2. New value as a percentage of the initial value
    if initial_value == 0:
        val_str = "Undefined (initial value is zero)"
        if new_value == 0:
            # (0 / 0) * 100 is indeterminate.
            val_str = "Undefined (both values are zero)"
        print_stat(label_percent_of_initial, val_str)
    else:
        percent_of_initial = (new_value / initial_value) * 100
        print_stat(label_percent_of_initial, f"{percent_of_initial:.2f}%")

    # 3. Percentage difference
    if initial_value == 0:
        val_str = "Undefined (cannot calculate percentage change from zero to a non-zero value)"
        if new_value == 0:
            # Change from 0 to 0 is 0. Percentage difference is 0%.
            val_str = "0.00% (no change from zero to zero)"
        print_stat(label_percentage_diff, val_str)
    else:
        # initial_value is not zero
        percentage_diff = (decimal_diff / initial_value) * 100
        print_stat(label_percentage_diff, f"{percentage_diff:.2f}%")

def main():
    """
    Parses command-line arguments and initiates the difference calculations.
    """
    parser = argparse.ArgumentParser(
        description=(
            "Calculates and prints decimal difference, new value as a "
            "percentage of initial, and percentage difference between two values."
        ),
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument(
        "-i", "--initial",
        type=float,
        required=True,
        help="The initial value (numeric)."
    )
    parser.add_argument(
        "-n", "--new",
        type=float,
        required=True,
        help="The new value (numeric)."
    )

    args = parser.parse_args()

    calculate_and_print_differences(args.initial, args.new)

if __name__ == "__main__":
    main()
