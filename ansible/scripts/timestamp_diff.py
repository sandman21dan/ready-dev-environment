import argparse
from datetime import datetime

def calculate_timedelta(timestamp1, timestamp2):
    """
    Calculates the timedelta between two timestamps in the format "YYYY-MM-DDTHH:MM:SS.sss+0000".

    Args:
        timestamp1: The first timestamp string.
        timestamp2: The second timestamp string.

    Returns:
        A timedelta object representing the difference between the two timestamps.
        Returns None if there's an error parsing the timestamps.
    """
    try:
        # Parse the timestamp strings into datetime objects
        dt1 = datetime.strptime(timestamp1, "%Y-%m-%dT%H:%M:%S.%f%z")
        dt2 = datetime.strptime(timestamp2, "%Y-%m-%dT%H:%M:%S.%f%z")

        # Calculate the timedelta
        timedelta = dt2 - dt1
        return timedelta

    except ValueError:
        print("Error: Invalid timestamp format. Please use 'YYYY-MM-DDTHH:MM:SS.sss+0000' format.")
        return None


def main():
    # Create an argument parser
    parser = argparse.ArgumentParser(description="Calculate the timedelta between two timestamps.")

    # Add arguments for the timestamps
    parser.add_argument("--t1", required=True, help="The first timestamp in YYYY-MM-DDTHH:MM:SS.sss+0000 format")
    parser.add_argument("--t2", required=True, help="The second timestamp in YYYY-MM-DDTHH:MM:SS.sss+0000 format")

    # Parse the arguments
    args = parser.parse_args()

    # Calculate the timedelta
    time_difference = calculate_timedelta(args.t1, args.t2)

    if time_difference:
        print(time_difference)


if __name__ == "__main__":
    main()
