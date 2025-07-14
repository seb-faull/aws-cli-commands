import os
import pandas as pd

def count_lines_in_file(file_path):
    try:
        # For CSV and TXT files
        if file_path.endswith(('.csv', '.txt', '.ppl')):
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                return sum(1 for _ in f)
        # For Excel files
        elif file_path.endswith(('.xls', '.xlsx', '.xlsm')):
            xl = pd.ExcelFile(file_path)
            return sum(len(xl.parse(sheet_name)) for sheet_name in xl.sheet_names)
        else:
            return 0
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
        return 0

def count_total_lines(base_folder):
    total_lines = 0
    for root, _, files in os.walk(base_folder):
        for file in files:
            if file.endswith(('.csv', '.txt', '.ppl', '.xls', '.xlsx', '.xlsm')):
                file_path = os.path.join(root, file)
                lines = count_lines_in_file(file_path)
                total_lines += lines
                print(f"{file}: {lines} lines")
    return total_lines

# Update this path to your folder
folder_path = r'C:/Users/FaullS/.aws/s3Downloads-4.9MB-or-less'

total = count_total_lines(folder_path)
print("\nTotal lines across all files:", total)
