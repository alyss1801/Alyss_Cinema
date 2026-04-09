#!/usr/bin/env python3
import os
import re

import mysql.connector

conn = mysql.connector.connect(
    host=os.environ.get('MYSQL_HOST', 'localhost'),
    port=int(os.environ.get('MYSQL_PORT', '3306')),
    user=os.environ.get('MYSQL_USER', 'root'),
    password=os.environ.get('MYSQL_PASSWORD', ''),
    database=os.environ.get('MYSQL_DATABASE', 'railway')
)

cursor = conn.cursor()

def import_file(filename, handle_delimiter=False):
    """Import SQL file with proper statement parsing."""
    print(f'Importing {filename}...', end=' ', flush=True)
    
    with open(filename, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Remove comments
    content = re.sub(r'--.*\n', '\n', content)  # -- comments
    
    if handle_delimiter:
        # Handle DELIMITER $$ ... DELIMITER ;
        parts = content.split('DELIMITER $$')
        statements = []
        for i, part in enumerate(parts[1:]):  # Skip first part
            stmt = part.split('DELIMITER ;')[0].strip()
            if stmt:
                statements.append(stmt)
    else:
        # Normal split by ;
        statements = [s.strip() for s in content.split(';') if s.strip()]
    
    count = 0
    errors = 0
    for stmt in statements:
        if not stmt or stmt.startswith('--') or stmt.startswith('USE'):
            continue
        
        try:
            cursor.execute(stmt)
            conn.commit()
            count += 1
        except Exception as e:
            error_msg = str(e)
            # Ignore expected errors
            if 'already exists' in error_msg or 'Duplicate' in error_msg:
                count += 1
            else:
                errors += 1
                if errors <= 3:  # Show first 3 errors only
                    print(f"\n  ⚠️  {error_msg[:100]}")
    
    print(f'✅ {count} statements')
    return count > 0

# Import files
print('='*50)
print('DATABASE IMPORT')
print('='*50)

import_file('schema.sql', handle_delimiter=False)
import_file('data.sql', handle_delimiter=False)
import_file('triggers.sql', handle_delimiter=True)
import_file('procedures_crud.sql', handle_delimiter=True)
import_file('procedures_query.sql', handle_delimiter=True)
import_file('functions.sql', handle_delimiter=True)

# Verify
print('\n' + '='*50)
print('VERIFICATION')
print('='*50)

cursor.execute('SHOW TABLES')
tables = [t[0] for t in cursor.fetchall()]
print(f'✅ Tables: {len(tables)} - {", ".join(tables[:5])}...')

queries = [
    ('NguoiDung', 'SELECT COUNT(*) FROM NguoiDung'),
    ('Phim', 'SELECT COUNT(*) FROM Phim'),
    ('Booking', 'SELECT COUNT(*) FROM Booking'),
    ('KhachHang', 'SELECT COUNT(*) FROM KhachHang'),
    ('SuatChieu', 'SELECT COUNT(*) FROM SuatChieu'),
]

for name, query in queries:
    try:
        cursor.execute(query)
        count = cursor.fetchone()[0]
        print(f'✅ {name}: {count} records')
    except Exception as e:
        print(f'❌ {name}: {str(e)[:50]}')

conn.close()
print('\n✅ Import complete!')
