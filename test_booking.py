"""Quick test script for booking flow."""
import requests
import json
import re

BASE = 'http://localhost:5000'
s = requests.Session()

print("=== TEST 1: Register new account ===")
r = s.post(f'{BASE}/register', data={
    'hoTen': 'Test User',
    'email': 'test@demo.com',
    'soDienThoai': '0911111111',
    'matKhau': 'demo123',
    'matKhau2': 'demo123',
    'ngaySinh': '2000-01-15',
    'gioiTinh': 'Nam',
    'diaChi': 'TP. HCM'
}, allow_redirects=False)
print(f"  Register: {r.status_code} -> {r.headers.get('Location', 'N/A')}")

print("\n=== TEST 2: Login with new account ===")
r = s.post(f'{BASE}/login', data={'email': 'test@demo.com', 'matKhau': 'demo123'}, allow_redirects=False)
print(f"  Login: {r.status_code} -> {r.headers.get('Location', 'N/A')}")

print("\n=== TEST 3: Check wallet ===")
r = s.get(f'{BASE}/wallet')
balance = re.search(r'<h2[^>]*>([\d.,]+)\s*<small', r.text)
print(f"  Wallet: {balance.group(1) if balance else 'N/A'} VND")

print("\n=== TEST 4: Book tickets ===")
r = s.get(f'{BASE}/api/seats/12').json()
avail = [x for x in r['seats'] if x['trangThaiDat'] == 'Trong']
ghe = [avail[0]['maGhe'], avail[1]['maGhe']]
print(f"  Available: {len(avail)}, picking: {ghe}")

r = s.post(f'{BASE}/bookings/new', data={
    'maSuatChieu': '12',
    'danhSachGhe': json.dumps(ghe),
    'maCodeGiamGia': ''
}, allow_redirects=False)
print(f"  Booking POST: {r.status_code} -> {r.headers.get('Location', 'N/A')}")
if r.status_code == 302:
    r2 = s.get(BASE + r.headers['Location'])
    alerts = re.findall(r'alert-dismissible[^>]*>(.*?)</div>', r2.text, re.DOTALL)
    for a in alerts:
        clean = re.sub(r'<[^>]+>', '', a).strip()
        if clean:
            print(f"  Flash: {clean}")

print("\n=== TEST 5: Check wallet after booking ===")
r = s.get(f'{BASE}/wallet')
balance = re.search(r'<h2[^>]*>([\d.,]+)\s*<small', r.text)
print(f"  Wallet: {balance.group(1) if balance else 'N/A'} VND")
has_payment = 'ThanhCong' in r.text or 'Thành công' in r.text
print(f"  Has payment record: {has_payment}")

print("\n=== TEST 6: My bookings ===")
r = s.get(f'{BASE}/bookings')
booking_count = r.text.count('Confirmed') + r.text.count('Pending')
print(f"  Bookings visible: {booking_count}")

print("\n=== DONE ===")

