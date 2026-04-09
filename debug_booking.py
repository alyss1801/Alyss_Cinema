import requests, re, json
s = requests.Session()
s.post('http://localhost:5000/login', data={'email': 'an.nguyen@gmail.com', 'matKhau': '123456'})

# Use showtime 12 which has plenty of available seats
r = s.get('http://localhost:5000/api/seats/12').json()
avail = [x for x in r['seats'] if x['trangThaiDat'] == 'Trong']
print(f"Available: {len(avail)} seats for showtime 12")
ghe = [avail[0]['maGhe'], avail[1]['maGhe']]
print(f"Booking seats: {ghe}")

# Do POST booking
r = s.post('http://localhost:5000/bookings/new',
           data={'maSuatChieu': '12', 'danhSachGhe': json.dumps(ghe), 'maCodeGiamGia': ''},
           allow_redirects=False)
print(f"POST status: {r.status_code}, Location: {r.headers.get('Location')}")

if r.status_code == 500:
    frames = re.findall(r'File <cite.*?>"(.*?)"</cite>.*?line <em.*?>(.*?)</em>.*?in <code.*?>(.*?)</code>', r.text)
    for f in frames[-5:]:
        print(f"  {f[0]}:{f[1]} in {f[2]}")
    exc = re.findall(r'<h1>(.*?)</h1>', r.text)
    print("Exception:", exc)
    pre_blocks = re.findall(r'<pre class="line current">(.*?)</pre>', r.text, re.DOTALL)
    for p in pre_blocks[-3:]:
        clean = re.sub(r'<[^>]+>', '', p).strip()
        print("Code:", clean)
elif r.status_code == 302:
    # Follow redirect
    loc = r.headers.get('Location', '/')
    r2 = s.get('http://localhost:5000' + loc if loc.startswith('/') else loc)
    # Extract flash messages
    alerts = re.findall(r'alert-dismissible[^>]*>(.*?)</div>', r2.text, re.DOTALL)
    for a in alerts:
        clean = re.sub(r'<[^>]+>', '', a).strip()
        if clean:
            print(f"Flash: {clean}")

# Check wallet
r = s.get('http://localhost:5000/wallet')
balance = re.search(r'<h2[^>]*>([\d.,]+)\s*<small', r.text)
if balance:
    print(f"Wallet balance: {balance.group(1)} VND")
