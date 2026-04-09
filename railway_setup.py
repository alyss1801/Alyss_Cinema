import os

import mysql.connector

conn = mysql.connector.connect(
    host=os.environ.get('MYSQL_HOST', 'localhost'),
    port=int(os.environ.get('MYSQL_PORT', '3306')),
    user=os.environ.get('MYSQL_USER', 'root'),
    password=os.environ.get('MYSQL_PASSWORD', ''),
    database=os.environ.get('MYSQL_DATABASE', 'railway'),
    charset='utf8mb4',
)
cur = conn.cursor()

try:
    cur.execute('ALTER TABLE KhachHang ADD COLUMN soDuVi DECIMAL(15,2) NOT NULL DEFAULT 5000000')
    print('Added column KhachHang.soDuVi')
except Exception as e:
    print(f'ALTER skipped: {e}')

cur.execute('UPDATE KhachHang SET soDuVi = 5000000 WHERE soDuVi IS NULL OR soDuVi = 0')
cur.execute("UPDATE NguoiDung SET matKhau='8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92'")
conn.commit()

checks = [
    ('users', 'SELECT COUNT(*) FROM NguoiDung'),
    ('movies', 'SELECT COUNT(*) FROM Phim'),
    ('bookings', 'SELECT COUNT(*) FROM Booking'),
    ('seats', 'SELECT COUNT(*) FROM Ghe'),
    ('wallet_rows', 'SELECT COUNT(*) FROM KhachHang WHERE soDuVi IS NOT NULL'),
]

for name, query in checks:
    cur.execute(query)
    print(f'{name}: {cur.fetchone()[0]}')

cur.close()
conn.close()
print('done')
