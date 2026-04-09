# BTL2 — HỆ THỐNG ĐẶT VÉ RẠP CHIẾU PHIM

> Bài Tập Lớn 2 — Môn Hệ Cơ Sở Dữ Liệu  
> Stack: **MySQL 8.0** + **Python Flask** + **HTML/CSS/JS (Bootstrap 5)**

---

## 📁 Cấu trúc Project

```
Form_BTL2_Datatbase/
├── schema.sql              # Tạo database & tất cả bảng (16 bảng)
├── data.sql                # Dữ liệu mẫu thực tế
├── triggers.sql            # 8 triggers (ràng buộc + dẫn xuất)
├── procedures_crud.sql     # 3 stored procedure CRUD cho Booking
├── procedures_query.sql    # 2 stored procedure hiển thị/thống kê
├── functions.sql           # 2 functions (tích lũy điểm + tính giá ghế)
├── README.md               # File hướng dẫn này
└── cinema_app/             # Ứng dụng Flask
    ├── app.py              # Flask app chính (routes + API)
    ├── config.py           # Cấu hình DB (không hardcode)
    ├── db.py               # Helper kết nối MySQL (connection pool)
    ├── requirements.txt    # Python dependencies
    ├── templates/
    │   ├── base.html       # Layout chung (navbar, footer)
    │   ├── index.html      # Trang chủ (phim đang chiếu)
    │   └── bookings/
    │       ├── list.html   # Danh sách booking (3.2)
    │       ├── form.html   # Thêm/Sửa booking (3.1)
    │       └── stats.html  # Thống kê doanh thu (3.3)
    └── static/
        ├── css/style.css   # Custom CSS
        └── js/main.js      # JavaScript chung
```

---

## 🚀 Hướng dẫn Cài đặt & Chạy

### Yêu cầu hệ thống

- **MySQL 8.0+** (đã cài đặt và đang chạy)
- **Python 3.8+**
- **pip** (Python package manager)

### Bước 1: Tạo Database

Mở MySQL client (MySQL Workbench, terminal, hoặc phpMyAdmin) và chạy các file SQL **theo thứ tự**:

```sql
-- 1. Tạo schema (database + bảng + ràng buộc CHECK)
SOURCE D:/Form_BTL2_Datatbase/schema.sql;

-- 2. Chèn dữ liệu mẫu
SOURCE D:/Form_BTL2_Datatbase/data.sql;

-- 3. Tạo triggers
SOURCE D:/Form_BTL2_Datatbase/triggers.sql;

-- 4. Tạo stored procedures CRUD
SOURCE D:/Form_BTL2_Datatbase/procedures_crud.sql;

-- 5. Tạo stored procedures hiển thị
SOURCE D:/Form_BTL2_Datatbase/procedures_query.sql;

-- 6. Tạo functions
SOURCE D:/Form_BTL2_Datatbase/functions.sql;
```

Hoặc dùng terminal:

```bash
mysql -u root -p < schema.sql
mysql -u root -p RapChieuPhim < data.sql
mysql -u root -p RapChieuPhim < triggers.sql
mysql -u root -p RapChieuPhim < procedures_crud.sql
mysql -u root -p RapChieuPhim < procedures_query.sql
mysql -u root -p RapChieuPhim < functions.sql
```

### Bước 2: Cài đặt Python dependencies

```bash
cd cinema_app
pip install -r requirements.txt
```

### Bước 3: Cấu hình kết nối MySQL

Mở file `cinema_app/config.py` và cập nhật thông tin MySQL:

```python
MYSQL_HOST = 'localhost'
MYSQL_PORT = 3306
MYSQL_USER = 'root'           # ← Đổi nếu dùng user khác
MYSQL_PASSWORD = ''            # ← Đổi password MySQL của bạn
MYSQL_DATABASE = 'RapChieuPhim'
```

Hoặc dùng biến môi trường:

```bash
set MYSQL_USER=root
set MYSQL_PASSWORD=your_password
```

### Bước 4: Chạy ứng dụng

```bash
cd cinema_app
python app.py
```

Ứng dụng sẽ chạy tại: **http://localhost:5000**

---

## 📋 Danh sách Bảng (16 bảng)

| # | Bảng | Mô tả | Ghi chú |
|---|------|--------|---------|
| 1 | `NguoiDung` | Tài khoản hệ thống | **Superclass** |
| 2 | `KhachHang` | Thông tin khách hàng | **Subclass** |
| 3 | `QuanTriVien` | Thông tin admin | **Subclass** |
| 4 | `Phim` | Thông tin phim | Có **liên kết đệ quy** (phim liên quan) |
| 5 | `TheLoai` | Danh mục thể loại | — |
| 6 | `TheLoaiPhim` | Liên kết phim-thể loại | **Thuộc tính đa trị** (N:M) |
| 7 | `PhongChieu` | Phòng chiếu | `sucChua` = **DẪN XUẤT** |
| 8 | `Ghe` | Ghế trong phòng | **Thực thể YẾU** |
| 9 | `SuatChieu` | Suất chiếu phim | — |
| 10 | `KhuyenMai` | Mã khuyến mãi | — |
| 11 | `Booking` | Đơn đặt vé | **Bảng trung tâm CRUD** |
| 12 | `ChiTietBooking` | Chi tiết ghế/booking | **Thực thể YẾU** |
| 13 | `Ve` | Vé điện tử | Liên kết **1:1** với Booking |
| 14 | `ThanhToan` | Thanh toán | — |
| 15 | `DanhGia` | Đánh giá phim | — |
| 16 | `DiemTichLuy` | Lịch sử tích điểm | — |
| (bonus) | `LichSuHoatDong` | Log hoạt động | — |

---

## 🔒 10 Ràng buộc Ngữ nghĩa

| # | Ràng buộc | Hiện thực |
|---|-----------|-----------|
| RC1 | Giờ kết thúc > giờ bắt đầu suất chiếu | CHECK trong `SuatChieu` |
| RC2 | Ghế không đặt 2 lần cùng suất chiếu | TRIGGER `trg_KiemTraGheDaDat` |
| RC3 | Khách hàng đủ tuổi xem phim | CHECK trong SP `sp_ThemBooking` |
| RC4 | Tối đa 8 ghế / booking | CHECK trong SP `sp_ThemBooking` |
| RC5 | Điểm đánh giá 1-10 | CHECK trong `DanhGia` |
| RC6 | Mã KM không áp dụng sau hết hạn | CHECK trong SP `sp_ThemBooking` |
| RC7 | Lượt dùng KM ≤ tối đa | CHECK trong `KhuyenMai` + SP |
| RC8 | Không hủy booking sau suất chiếu bắt đầu | CHECK trong SP `sp_XoaBooking` |
| RC9 | SĐT 10 chữ số bắt đầu bằng 0 | CHECK trong `NguoiDung` |
| RC10 | Email chứa '@' và '.' | CHECK trong `NguoiDung` |

---

## ⚙️ Stored Procedures & Functions

### CRUD (Booking)
- `sp_ThemBooking(maKH, maSC, gheJSON, codeKM, OUT maBooking)` — Tạo booking mới
- `sp_SuaBooking(maBooking, trangThaiMoi)` — Sửa trạng thái
- `sp_XoaBooking(maBooking)` — Hủy booking (Pending only)

### Hiển thị / Thống kê
- `sp_DanhSachBookingTheoKhachHang(maKH, trangThai, tuNgay, denNgay)` — List booking với filter
- `sp_ThongKeDoanhThuPhim(tuNgay, denNgay, nguong)` — Thống kê doanh thu phim

### Functions
- `fn_TinhDiemTichLuy(maKH)` → INT — Tính & cập nhật điểm tích lũy (dùng CURSOR)
- `fn_GiaSuatChieuTheoGhe(maGhe, maSC)` → DECIMAL — Tính giá vé thực tế (dùng LOOP)

---

## 🌐 Giao diện Web

| Route | Mô tả |
|-------|--------|
| `/` | Trang chủ — phim đang chiếu |
| `/bookings` | Danh sách booking (filter, sort, phân trang) |
| `/bookings/new` | Form đặt vé mới (chọn ghế trực quan) |
| `/bookings/<id>/edit` | Sửa trạng thái booking |
| `/bookings/<id>/delete` | Hủy booking (POST) |
| `/bookings/stats` | Thống kê doanh thu + tính điểm tích lũy |
| `/api/seats/<id>` | API lấy sơ đồ ghế (JSON) |
| `/api/price/<ghe>/<sc>` | API tính giá vé (JSON) |

---

## 👥 Thành viên nhóm

| STT | Họ tên | MSSV | Phân công |
|-----|--------|------|-----------|
| 1 | | | |
| 2 | | | |
| 3 | | | |
| 4 | | | |
| 5 | | | |

---

## 📝 Ghi chú

- Đây là **bản nháp** — sẽ chỉnh sửa sau khi hoàn thiện BTL1 (EERD).
- Password MySQL mặc định là rỗng (`''`), cần cập nhật trong `config.py`.
- Dữ liệu mẫu sử dụng ngày trong tháng 02-03/2026 để phù hợp demo.
- Tất cả file SQL chạy được **độc lập theo thứ tự**: schema → data → triggers → procedures → functions.

---

## ☁️ Deploy Demo Lên Vercel

Lưu ý: Vercel **không chạy được MySQL local** (`localhost`). Bạn cần dùng MySQL cloud (Railway, Aiven, PlanetScale, Neon + MySQL, hoặc VPS).

### 1. Chuẩn bị database cloud

- Import schema/data/procedures/functions lên DB cloud bằng các file SQL có sẵn.
- Đảm bảo đã có cột ví ảo:

```sql
ALTER TABLE KhachHang ADD COLUMN soDuVi DECIMAL(15,2) NOT NULL DEFAULT 5000000;
UPDATE KhachHang SET soDuVi = 5000000;
```

### 2. Push code lên GitHub

```bash
git add .
git commit -m "Prepare Flask app for Vercel deployment"
git push
```

### 3. Import project vào Vercel

- Vào Vercel Dashboard → **New Project** → chọn repo này.
- Framework Preset: **Other** (hoặc để Auto Detect).

### 4. Set Environment Variables trên Vercel

Thêm các biến sau trong Project Settings → Environment Variables:

- `SECRET_KEY`
- `MYSQL_HOST`
- `MYSQL_PORT`
- `MYSQL_USER`
- `MYSQL_PASSWORD`
- `MYSQL_DATABASE`

Ví dụ:

- `MYSQL_HOST=db.xxxxx.railway.app`
- `MYSQL_PORT=3306`
- `MYSQL_USER=root`
- `MYSQL_PASSWORD=********`
- `MYSQL_DATABASE=RapChieuPhim`

### 5. Deploy

- Bấm **Deploy**.
- Sau khi deploy xong, mở domain Vercel để test:
    - `/login`
    - `/register`
    - `/bookings/new`
    - `/wallet`

### 6. Nếu gặp lỗi kết nối DB

- Kiểm tra DB cloud có whitelist IP/allow public access.
- Kiểm tra đúng host/port/user/password.
- Với một số nhà cung cấp DB, cần bật SSL/TLS riêng.
