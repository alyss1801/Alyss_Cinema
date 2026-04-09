"""
Helper script: Import SQL files vào MySQL bằng subprocess.
MySQL xử lý DELIMITER natively — không cần parse thủ công.
"""
import subprocess
import sys
import os

MYSQL_EXE = r'C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe'

def import_file(filepath):
    """Import 1 file SQL qua mysql.exe stdin."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    result = subprocess.run(
        [MYSQL_EXE, '-u', 'root', '--default-character-set=utf8mb4'],
        input=content,
        capture_output=True,
        text=True,
        encoding='utf-8'
    )

    if result.returncode != 0:
        return False, result.stderr.strip()
    if result.stderr.strip():
        return True, result.stderr.strip()
    return True, None


def main():
    files = sys.argv[1:] if len(sys.argv) > 1 else []
    if not files:
        print("Usage: python import_sql.py file1.sql file2.sql ...")
        return

    ok_count = 0
    fail_count = 0

    for filepath in files:
        if not os.path.exists(filepath):
            print(f"[ERROR] Not found: {filepath}")
            fail_count += 1
            continue

        filename = os.path.basename(filepath)
        print(f"[IMPORTING] {filename} ...", end=' ')
        success, msg = import_file(filepath)
        if success:
            ok_count += 1
            print("OK")
            if msg:
                for line in msg.split('\n')[:5]:
                    print(f"  [WARN] {line}")
        else:
            fail_count += 1
            print(f"FAILED")
            if msg:
                for line in msg.split('\n')[:5]:
                    print(f"  [ERR] {line}")

    print(f"\n[DONE] {ok_count} succeeded, {fail_count} failed.")


if __name__ == '__main__':
    main()
