# ============================================================
# BTL2 — HỆ THỐNG ĐẶT VÉ RẠP CHIẾU PHIM
# File: app.py
# Mục đích: Flask app chính — routes và API endpoints
# ============================================================

from flask import Flask, render_template, request, redirect, url_for, flash, jsonify, session
from functools import wraps
try:
    from .config import Config
    from . import db
except ImportError:
    from config import Config
    import db
import json
import hashlib
import os
from mysql.connector import Error
from datetime import datetime, date
from decimal import Decimal

app = Flask(__name__)
app.config.from_object(Config)

# Khởi tạo connection pool khi app start
with app.app_context():
    try:
        db.init_pool()
    except Exception as e:
        print(f"[WARNING] Không thể kết nối MySQL: {e}")
        print("[WARNING] Hãy đảm bảo MySQL đang chạy và database RapChieuPhim đã được tạo.")


# ============================================================
# AUTH HELPERS
# ============================================================
def login_required(f):
    """Decorator bắt buộc đăng nhập."""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            flash('Vui lòng đăng nhập để tiếp tục.', 'warning')
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function


def hash_password(password):
    """Hash password bằng SHA-256 (demo)."""
    return hashlib.sha256(password.encode('utf-8')).hexdigest()


def get_current_user():
    """Lấy thông tin user hiện tại từ session."""
    if 'user_id' not in session:
        return None
    try:
        user = db.execute_query("""
            SELECT nd.maNguoiDung, nd.hoTen, nd.email, nd.soDienThoai,
                   nd.vaiTro, kh.soDuVi, kh.hangThanhVien, kh.diemTichLuy
            FROM NguoiDung nd
            LEFT JOIN KhachHang kh ON nd.maNguoiDung = kh.maKhachHang
            WHERE nd.maNguoiDung = %s AND nd.trangThai = 'HoatDong'
        """, (session['user_id'],), fetchone=True)
        return user
    except Error:
        return None


@app.context_processor
def inject_user():
    """Inject current_user vào tất cả templates."""
    return dict(current_user=get_current_user())


# ============================================================
# ĐĂNG KÝ
# ============================================================
@app.route('/register', methods=['GET', 'POST'])
def register():
    if 'user_id' in session:
        return redirect(url_for('index'))

    if request.method == 'POST':
        try:
            ho_ten = request.form.get('hoTen', '').strip()
            email = request.form.get('email', '').strip()
            sdt = request.form.get('soDienThoai', '').strip()
            mat_khau = request.form.get('matKhau', '').strip()
            mat_khau2 = request.form.get('matKhau2', '').strip()
            ngay_sinh = request.form.get('ngaySinh', '').strip()
            gioi_tinh = request.form.get('gioiTinh', 'Khac').strip()
            dia_chi = request.form.get('diaChi', '').strip()

            # Validate
            if not all([ho_ten, email, sdt, mat_khau, ngay_sinh]):
                flash('Vui lòng điền đầy đủ thông tin bắt buộc.', 'warning')
                return render_template('register.html')
            if mat_khau != mat_khau2:
                flash('Mật khẩu xác nhận không khớp.', 'danger')
                return render_template('register.html')
            if len(mat_khau) < 4:
                flash('Mật khẩu phải có ít nhất 4 ký tự.', 'danger')
                return render_template('register.html')

            # Check email trùng
            existing = db.execute_query("SELECT 1 FROM NguoiDung WHERE email = %s", (email,), fetchone=True)
            if existing:
                flash('Email đã được sử dụng. Vui lòng chọn email khác.', 'danger')
                return render_template('register.html')

            # Insert NguoiDung
            db.execute_query("""
                INSERT INTO NguoiDung (hoTen, email, matKhau, soDienThoai, vaiTro, trangThai)
                VALUES (%s, %s, %s, %s, 'KhachHang', 'HoatDong')
            """, (ho_ten, email, hash_password(mat_khau), sdt), commit=True)

            # Lấy ID vừa insert
            new_user = db.execute_query(
                "SELECT maNguoiDung FROM NguoiDung WHERE email = %s", (email,), fetchone=True)
            user_id = new_user['maNguoiDung']

            # Insert KhachHang (ví ảo 5 triệu)
            db.execute_query("""
                INSERT INTO KhachHang (maKhachHang, ngaySinh, gioiTinh, diaChi, diemTichLuy, hangThanhVien, soDuVi)
                VALUES (%s, %s, %s, %s, 0, 'Thuong', 5000000)
            """, (user_id, ngay_sinh, gioi_tinh, dia_chi or None), commit=True)

            flash('Đăng ký thành công! Tài khoản của bạn có sẵn 5.000.000 VND trong ví. Hãy đăng nhập.', 'success')
            return redirect(url_for('login'))

        except Error as e:
            flash(f'Lỗi đăng ký hoặc kết nối CSDL: {e}', 'danger')
            return render_template('register.html')

    return render_template('register.html')


# ============================================================
# ĐĂNG NHẬP
# ============================================================
@app.route('/login', methods=['GET', 'POST'])
def login():
    if 'user_id' in session:
        return redirect(url_for('index'))

    if request.method == 'POST':
        try:
            email = request.form.get('email', '').strip()
            mat_khau = request.form.get('matKhau', '').strip()

            if not email or not mat_khau:
                flash('Vui lòng nhập email và mật khẩu.', 'warning')
                return render_template('login.html')

            user = db.execute_query("""
                SELECT maNguoiDung, hoTen, matKhau, vaiTro, trangThai
                FROM NguoiDung WHERE email = %s
            """, (email,), fetchone=True)

            if not user or user['matKhau'] != hash_password(mat_khau):
                flash('Email hoặc mật khẩu không đúng.', 'danger')
                return render_template('login.html')

            if user['trangThai'] != 'HoatDong':
                flash('Tài khoản đã bị khóa.', 'danger')
                return render_template('login.html')

            # OK — tạo session
            session['user_id'] = user['maNguoiDung']
            session['user_name'] = user['hoTen']
            session['user_role'] = user['vaiTro']

            flash(f'Chào mừng {user["hoTen"]}!', 'success')
            return redirect(url_for('index'))
        except Error as e:
            flash(f'Lỗi kết nối CSDL: {e}', 'danger')
            return render_template('login.html')

    return render_template('login.html')


# ============================================================
# ĐĂNG XUẤT
# ============================================================
@app.route('/logout')
def logout():
    session.clear()
    flash('Đã đăng xuất.', 'info')
    return redirect(url_for('login'))


# ============================================================
# HELPER: Chuyển đổi kiểu dữ liệu cho JSON serialization
# ============================================================
def serialize_row(row):
    """Chuyển đổi các giá trị không JSON-serializable."""
    if row is None:
        return None
    result = {}
    for key, value in row.items():
        if isinstance(value, Decimal):
            result[key] = float(value)
        elif isinstance(value, (datetime, date)):
            result[key] = value.isoformat()
        else:
            result[key] = value
    return result


def serialize_rows(rows):
    """Serialize danh sách rows."""
    return [serialize_row(r) for r in rows] if rows else []


# ============================================================
# TRANG CHỦ
# ============================================================
@app.route('/')
def index():
    """Trang chủ — hiển thị phim đang chiếu."""
    def build_disney_movies():
        disney_info = {
            'coco': {
                'tenPhim': 'Coco',
                'daoDien': 'Lee Unkrich, Adrian Molina',
                'thoiLuong': 105,
                'ngonNgu': 'Tieng Anh',
                'theLoai': 'Hoat hinh, Gia dinh, Am nhac',
                'diemDanhGiaTB': 8.4,
                'gioiHanDoTuoi': 'P',
                'moTa': 'Cau chuyen ve Miguel trong hanh trinh am nhac o Vung Dat Linh Hon.'
            },
            'elemental': {
                'tenPhim': 'Elemental',
                'daoDien': 'Peter Sohn',
                'thoiLuong': 101,
                'ngonNgu': 'Tieng Anh',
                'theLoai': 'Hoat hinh, Hai huoc, Lang man',
                'diemDanhGiaTB': 7.0,
                'gioiHanDoTuoi': 'P',
                'moTa': 'Tinh ban va tinh yeu cua Ember va Wade trong thanh pho cac nguyen to.'
            },
            'elio': {
                'tenPhim': 'Elio',
                'daoDien': 'Adrian Molina',
                'thoiLuong': 98,
                'ngonNgu': 'Tieng Anh',
                'theLoai': 'Hoat hinh, Phieu luu, Khoa hoc vien tuong',
                'diemDanhGiaTB': 7.1,
                'gioiHanDoTuoi': 'P',
                'moTa': 'Cau be Elio vo tinh tro thanh dai su Trai Dat truoc cong dong ngoai hanh tinh.'
            },
            'fiding_nemo': {
                'tenPhim': 'Finding Nemo',
                'daoDien': 'Andrew Stanton',
                'thoiLuong': 100,
                'ngonNgu': 'Tieng Anh',
                'theLoai': 'Hoat hinh, Phieu luu, Gia dinh',
                'diemDanhGiaTB': 8.2,
                'gioiHanDoTuoi': 'P',
                'moTa': 'Hanh trinh tim con xuyen dai duong cua ong bo ca he Marlin.'
            },
            'frozen2': {
                'tenPhim': 'Frozen II',
                'daoDien': 'Chris Buck, Jennifer Lee',
                'thoiLuong': 103,
                'ngonNgu': 'Tieng Anh',
                'theLoai': 'Hoat hinh, Gia dinh, Nhac kich',
                'diemDanhGiaTB': 6.8,
                'gioiHanDoTuoi': 'P',
                'moTa': 'Elsa, Anna va nhung nguoi ban buoc vao cuoc phieu luu giai ma qua khu Arendelle.'
            },
            'good_dino': {
                'tenPhim': 'The Good Dinosaur',
                'daoDien': 'Peter Sohn',
                'thoiLuong': 93,
                'ngonNgu': 'Tieng Anh',
                'theLoai': 'Hoat hinh, Gia dinh, Phieu luu',
                'diemDanhGiaTB': 6.7,
                'gioiHanDoTuoi': 'P',
                'moTa': 'Tinh ban giua khung long Arlo va cau be Spot trong the gioi tien su gia dinh.'
            },
            'inside_out1': {
                'tenPhim': 'Inside Out',
                'daoDien': 'Pete Docter',
                'thoiLuong': 95,
                'ngonNgu': 'Tieng Anh',
                'theLoai': 'Hoat hinh, Hai huoc, Tam ly',
                'diemDanhGiaTB': 8.1,
                'gioiHanDoTuoi': 'P',
                'moTa': 'Chuyen dong cam xuc ben trong tam tri co be Riley khi doi moi moi truong song.'
            },
            'robin_hood': {
                'tenPhim': 'Robin Hood',
                'daoDien': 'Wolfgang Reitherman',
                'thoiLuong': 83,
                'ngonNgu': 'Tieng Anh',
                'theLoai': 'Hoat hinh, Phieu luu, Hai huoc',
                'diemDanhGiaTB': 7.5,
                'gioiHanDoTuoi': 'P',
                'moTa': 'Phien ban Disney kinh dien voi Robin Hood va Little John duoi hinh dang dong vat.'
            },
            'turning_red': {
                'tenPhim': 'Turning Red',
                'daoDien': 'Domee Shi',
                'thoiLuong': 100,
                'ngonNgu': 'Tieng Anh',
                'theLoai': 'Hoat hinh, Hai huoc, Truong thanh',
                'diemDanhGiaTB': 7.0,
                'gioiHanDoTuoi': 'P',
                'moTa': 'Mei buoc vao tuoi day thi voi "nang cap" bat ngo: bien thanh gau do khong lo.'
            },
            'up': {
                'tenPhim': 'Up',
                'daoDien': 'Pete Docter',
                'thoiLuong': 96,
                'ngonNgu': 'Tieng Anh',
                'theLoai': 'Hoat hinh, Phieu luu, Gia dinh',
                'diemDanhGiaTB': 8.3,
                'gioiHanDoTuoi': 'P',
                'moTa': 'Ong lao Carl cung huong dao sinh Russell thuc hien chuyen phieu luu bang nha bong bay.'
            },
            'wall-e': {
                'tenPhim': 'WALL-E',
                'daoDien': 'Andrew Stanton',
                'thoiLuong': 98,
                'ngonNgu': 'Tieng Anh',
                'theLoai': 'Hoat hinh, Khoa hoc vien tuong, Lang man',
                'diemDanhGiaTB': 8.4,
                'gioiHanDoTuoi': 'P',
                'moTa': 'Robot don rac WALL-E va hanh trinh cuu lay Trai Dat day xuc dong.'
            },
            'zootopia': {
                'tenPhim': 'Zootopia',
                'daoDien': 'Byron Howard, Rich Moore',
                'thoiLuong': 108,
                'ngonNgu': 'Tieng Anh',
                'theLoai': 'Hoat hinh, Hai huoc, Pha an',
                'diemDanhGiaTB': 8.0,
                'gioiHanDoTuoi': 'P',
                'moTa': 'Co tho canh sat Judy Hopps va chu cao Nick Wilde cung nhau pha vu an lon.'
            },
            'zootopia2': {
                'tenPhim': 'Zootopia 2',
                'daoDien': 'Byron Howard (du kien)',
                'thoiLuong': 110,
                'ngonNgu': 'Tieng Anh',
                'theLoai': 'Hoat hinh, Hai huoc, Phieu luu',
                'diemDanhGiaTB': 0.0,
                'gioiHanDoTuoi': 'P',
                'moTa': 'Phan tiep theo du kien cua Zootopia, tiep tuc hanh trinh cua Judy va Nick.'
            },
        }

        disney_movies = []
        poster_dir = os.path.join(app.static_folder, 'poster_film')
        if os.path.isdir(poster_dir):
            for filename in sorted(os.listdir(poster_dir)):
                lower = filename.lower()
                if not lower.endswith(('.jpg', '.jpeg', '.png', '.webp')):
                    continue
                slug = os.path.splitext(lower)[0]
                if slug == 'neverness_to_everness':
                    continue
                info = disney_info.get(slug)
                if not info:
                    continue
                disney_movies.append({
                    **info,
                    'posterURL': f'/static/poster_film/{filename}'
                })
        return disney_movies

    disney_movies = build_disney_movies()
    try:
        movies = db.execute_query("""
            SELECT p.*, GROUP_CONCAT(tl.tenTheLoai SEPARATOR ', ') AS theLoai
            FROM Phim p
            LEFT JOIN TheLoaiPhim tlp ON p.maPhim = tlp.maPhim
            LEFT JOIN TheLoai tl ON tlp.maTheLoai = tl.maTheLoai
            WHERE p.trangThai = 'DangChieu'
            GROUP BY p.maPhim
            ORDER BY p.ngayKhoiChieu DESC
        """)
        return render_template('index.html', movies=movies or [], disney_movies=disney_movies)
    except Error as e:
        flash(f'Lỗi kết nối database: {e}', 'danger')
        return render_template('index.html', movies=[], disney_movies=disney_movies)


# ============================================================
# VÍ ẢO — XEM SỐ DƯ & LỊCH SỬ
# ============================================================
@app.route('/wallet')
@login_required
def wallet():
    """Xem số dư ví ảo + lịch sử thanh toán."""
    user = get_current_user()
    if not user or user['vaiTro'] != 'KhachHang':
        flash('Chức năng ví chỉ dành cho khách hàng.', 'warning')
        return redirect(url_for('index'))

    payments = db.execute_query("""
        SELECT tt.maThanhToan, tt.soTien, tt.phuongThuc, tt.trangThai AS trangThaiTT,
               tt.thoiGianTT, b.maBooking, p.tenPhim
        FROM ThanhToan tt
        INNER JOIN Booking b ON tt.maBooking = b.maBooking
        INNER JOIN SuatChieu sc ON b.maSuatChieu = sc.maSuatChieu
        INNER JOIN Phim p ON sc.maPhim = p.maPhim
        WHERE b.maKhachHang = %s
        ORDER BY tt.thoiGianTT DESC
    """, (session['user_id'],))

    return render_template('wallet.html', user=user, payments=payments or [])


# ============================================================
# 3.2 — DANH SÁCH BOOKING
# Route: GET /bookings
# Gọi stored procedure sp_DanhSachBookingTheoKhachHang
# ============================================================
@app.route('/bookings')
@login_required
def booking_list():
    """Hiển thị danh sách booking với bộ lọc."""
    try:
        # Lấy tham số filter từ query string
        trang_thai = request.args.get('trangThai', None)
        tu_ngay = request.args.get('tuNgay', None)
        den_ngay = request.args.get('denNgay', None)
        
        # Nếu là khách hàng, chỉ xem booking của mình
        user = get_current_user()
        ma_kh = session.get('user_id') if user and user['vaiTro'] == 'KhachHang' else request.args.get('maKhachHang', None, type=int)

        # Gọi stored procedure
        result = db.call_procedure(
            'sp_DanhSachBookingTheoKhachHang',
            args=(ma_kh, trang_thai if trang_thai else None, tu_ngay, den_ngay),
            commit=False
        )
        bookings = result['results']

        # Lấy danh sách khách hàng cho dropdown filter
        customers = db.execute_query("""
            SELECT kh.maKhachHang, nd.hoTen
            FROM KhachHang kh
            INNER JOIN NguoiDung nd ON kh.maKhachHang = nd.maNguoiDung
            ORDER BY nd.hoTen
        """)

        return render_template('bookings/list.html',
                               bookings=bookings or [],
                               customers=customers or [],
                               filters={
                                   'maKhachHang': ma_kh,
                                   'trangThai': trang_thai,
                                   'tuNgay': tu_ngay,
                                   'denNgay': den_ngay
                               })
    except Error as e:
        flash(f'Lỗi: {e}', 'danger')
        return render_template('bookings/list.html', bookings=[], customers=[], filters={})


# ============================================================
# 3.1 — FORM THÊM BOOKING
# Route: GET/POST /bookings/new
# Gọi stored procedure sp_ThemBooking
# ============================================================
@app.route('/bookings/new', methods=['GET', 'POST'])
@login_required
def booking_new():
    """Form tạo booking mới + thanh toán ví ảo."""
    if request.method == 'POST':
        try:
            ma_kh = session['user_id']  # Dùng user đang đăng nhập
            ma_sc = int(request.form['maSuatChieu'])
            danh_sach_ghe = request.form.get('danhSachGhe', '[]')
            ma_code_km = request.form.get('maCodeGiamGia', '').strip()

            # Validate phía server
            ghe_list = json.loads(danh_sach_ghe)
            if not ghe_list:
                flash('Vui lòng chọn ít nhất 1 ghế.', 'warning')
                return redirect(url_for('booking_new'))

            if len(ghe_list) > 8:
                flash('Số ghế đặt không được vượt quá 8 ghế.', 'warning')
                return redirect(url_for('booking_new'))

            # Kiểm tra số dư ví trước khi đặt
            user = get_current_user()
            if not user or user['soDuVi'] is None:
                flash('Lỗi tài khoản. Vui lòng đăng nhập lại.', 'danger')
                return redirect(url_for('login'))

            # Gọi stored procedure sp_ThemBooking
            result = db.call_procedure(
                'sp_ThemBooking',
                args=(ma_kh, ma_sc, json.dumps(ghe_list),
                      ma_code_km if ma_code_km else None, 0),
                out_params=1,
                commit=True
            )

            ma_booking_moi = result['out_params'][0] if result['out_params'] else None

            # Lấy tổng tiền booking vừa tạo
            booking_info = db.execute_query(
                "SELECT tongTien FROM Booking WHERE maBooking = %s",
                (ma_booking_moi,), fetchone=True)
            tong_tien = float(booking_info['tongTien']) if booking_info else 0

            # Kiểm tra số dư ví
            if float(user['soDuVi']) < tong_tien:
                # Không đủ tiền → hủy booking
                db.call_procedure('sp_XoaBooking', args=(ma_booking_moi,), commit=True)
                flash(f'Số dư ví không đủ! Cần {tong_tien:,.0f} VND nhưng ví chỉ có {float(user["soDuVi"]):,.0f} VND.', 'danger')
                return redirect(url_for('booking_new'))

            # Trừ tiền ví
            db.execute_query(
                "UPDATE KhachHang SET soDuVi = soDuVi - %s WHERE maKhachHang = %s",
                (tong_tien, ma_kh), commit=True)

            # Confirm booking
            db.call_procedure('sp_SuaBooking', args=(ma_booking_moi, 'Confirmed'), commit=True)

            # Tạo bản ghi thanh toán
            db.execute_query("""
                INSERT INTO ThanhToan (maBooking, soTien, phuongThuc, trangThai, thoiGianTT)
                VALUES (%s, %s, 'ViDienTu', 'ThanhCong', NOW())
            """, (ma_booking_moi, tong_tien), commit=True)

            flash(f'Đặt vé & thanh toán thành công! Mã booking: #{ma_booking_moi}. Đã trừ {tong_tien:,.0f} VND từ ví.', 'success')
            return redirect(url_for('booking_list'))

        except Error as e:
            error_msg = str(e)
            if '1644' in error_msg or '45000' in error_msg:
                parts = error_msg.split(': ', 1)
                flash(parts[-1] if len(parts) > 1 else error_msg, 'danger')
            else:
                flash(f'Lỗi hệ thống: {error_msg}', 'danger')
            return redirect(url_for('booking_new'))

        except (ValueError, json.JSONDecodeError) as e:
            flash(f'Dữ liệu không hợp lệ: {e}', 'danger')
            return redirect(url_for('booking_new'))

    # GET — hiển thị form
    try:
        showtimes = db.execute_query("""
            SELECT sc.maSuatChieu, p.tenPhim, pc.tenPhongChieu, pc.loaiPhong,
                   sc.thoiGianBatDau, sc.thoiGianKetThuc, sc.giaVeCoBan,
                   pc.maPhongChieu
            FROM SuatChieu sc
            INNER JOIN Phim p ON sc.maPhim = p.maPhim
            INNER JOIN PhongChieu pc ON sc.maPhongChieu = pc.maPhongChieu
            WHERE sc.trangThai = 'MoCua' AND sc.thoiGianBatDau > NOW()
            ORDER BY sc.thoiGianBatDau
        """)

        user = get_current_user()

        return render_template('bookings/form.html',
                               showtimes=showtimes or [],
                               user=user,
                               mode='new')
    except Error as e:
        flash(f'Lỗi: {e}', 'danger')
        return render_template('bookings/form.html',
                               showtimes=[], user=None, mode='new')


# ============================================================
# API — Lấy ghế theo suất chiếu (AJAX)
# Route: GET /api/seats/<int:showtime_id>
# ============================================================
@app.route('/api/seats/<int:showtime_id>')
def api_get_seats(showtime_id):
    """API trả về danh sách ghế của phòng chiếu (kèm trạng thái đặt)."""
    try:
        seats = db.execute_query("""
            SELECT 
                g.maGhe, g.hangGhe, g.soGhe, g.loaiGhe, g.trangThai,
                CASE 
                    WHEN EXISTS (
                        SELECT 1 FROM ChiTietBooking ctb
                        INNER JOIN Booking b ON ctb.maBooking = b.maBooking
                        WHERE ctb.maGhe = g.maGhe 
                          AND b.maSuatChieu = %s
                          AND b.trangThai IN ('Pending', 'Confirmed')
                    ) THEN 'DaDat'
                    WHEN g.trangThai != 'HoatDong' THEN 'KhongKhaDung'
                    ELSE 'Trong'
                END AS trangThaiDat
            FROM Ghe g
            INNER JOIN SuatChieu sc ON g.maPhongChieu = sc.maPhongChieu
            WHERE sc.maSuatChieu = %s
            ORDER BY g.hangGhe, g.soGhe
        """, (showtime_id, showtime_id))

        return jsonify({
            'success': True,
            'seats': serialize_rows(seats or [])
        })
    except Error as e:
        return jsonify({'success': False, 'error': str(e)}), 500


# ============================================================
# 3.1 — SỬA BOOKING (cập nhật trạng thái)
# Route: POST /bookings/<id>/edit
# Gọi stored procedure sp_SuaBooking
# ============================================================
@app.route('/bookings/<int:booking_id>/edit', methods=['GET', 'POST'])
@login_required
def booking_edit(booking_id):
    """Sửa trạng thái booking."""
    if request.method == 'POST':
        try:
            trang_thai_moi = request.form['trangThaiMoi']

            db.call_procedure(
                'sp_SuaBooking',
                args=(booking_id, trang_thai_moi),
                commit=True
            )
            flash(f'Cập nhật booking #{booking_id} thành công!', 'success')
            return redirect(url_for('booking_list'))

        except Error as e:
            error_msg = str(e)
            parts = error_msg.split(': ', 1)
            flash(parts[-1] if len(parts) > 1 else error_msg, 'danger')
            return redirect(url_for('booking_edit', booking_id=booking_id))

    # GET — hiển thị form sửa
    try:
        booking = db.execute_query("""
            SELECT b.*, nd.hoTen AS tenKhachHang, p.tenPhim,
                   sc.thoiGianBatDau, pc.tenPhongChieu
            FROM Booking b
            INNER JOIN KhachHang kh ON b.maKhachHang = kh.maKhachHang
            INNER JOIN NguoiDung nd ON kh.maKhachHang = nd.maNguoiDung
            INNER JOIN SuatChieu sc ON b.maSuatChieu = sc.maSuatChieu
            INNER JOIN Phim p ON sc.maPhim = p.maPhim
            INNER JOIN PhongChieu pc ON sc.maPhongChieu = pc.maPhongChieu
            WHERE b.maBooking = %s
        """, (booking_id,), fetchone=True)

        if not booking:
            flash('Booking không tồn tại.', 'warning')
            return redirect(url_for('booking_list'))

        seats = db.execute_query("""
            SELECT g.hangGhe, g.soGhe, g.loaiGhe, ctb.giaVe
            FROM ChiTietBooking ctb
            INNER JOIN Ghe g ON ctb.maGhe = g.maGhe
            WHERE ctb.maBooking = %s
            ORDER BY g.hangGhe, g.soGhe
        """, (booking_id,))

        return render_template('bookings/form.html',
                               booking=booking,
                               seats=seats or [],
                               mode='edit')
    except Error as e:
        flash(f'Lỗi: {e}', 'danger')
        return redirect(url_for('booking_list'))


# ============================================================
# 3.1 — XÓA BOOKING
# Route: POST /bookings/<id>/delete
# Gọi stored procedure sp_XoaBooking
# ============================================================
@app.route('/bookings/<int:booking_id>/delete', methods=['POST'])
@login_required
def booking_delete(booking_id):
    """Xóa (hủy) booking."""
    try:
        db.call_procedure(
            'sp_XoaBooking',
            args=(booking_id,),
            commit=True
        )
        flash(f'Booking #{booking_id} đã được hủy thành công.', 'success')
    except Error as e:
        error_msg = str(e)
        parts = error_msg.split(': ', 1)
        flash(parts[-1] if len(parts) > 1 else error_msg, 'danger')

    return redirect(url_for('booking_list'))


# ============================================================
# 3.3 — THỐNG KÊ DOANH THU
# Route: GET /bookings/stats
# Gọi sp_ThongKeDoanhThuPhim và fn_TinhDiemTichLuy
# ============================================================
@app.route('/bookings/stats')
@login_required
def booking_stats():
    """Thống kê doanh thu phim."""
    try:
        tu_ngay = request.args.get('tuNgay', None)
        den_ngay = request.args.get('denNgay', None)
        nguong = request.args.get('nguongDoanhThu', 0, type=float)
        ma_kh = request.args.get('maKhachHang', None, type=int)

        stats = []
        diem_tich_luy = None
        ten_kh = None

        # Gọi sp_ThongKeDoanhThuPhim
        if tu_ngay or den_ngay:
            result = db.call_procedure(
                'sp_ThongKeDoanhThuPhim',
                args=(tu_ngay, den_ngay, nguong),
                commit=False
            )
            stats = result['results']

        # Gọi fn_TinhDiemTichLuy (nếu có mã KH)
        if ma_kh:
            diem_tich_luy = db.call_function('fn_TinhDiemTichLuy', (ma_kh,))
            kh_info = db.execute_query("""
                SELECT nd.hoTen FROM NguoiDung nd
                INNER JOIN KhachHang kh ON kh.maKhachHang = nd.maNguoiDung
                WHERE kh.maKhachHang = %s
            """, (ma_kh,), fetchone=True)
            ten_kh = kh_info['hoTen'] if kh_info else None

        # Lấy danh sách KH cho dropdown
        customers = db.execute_query("""
            SELECT kh.maKhachHang, nd.hoTen
            FROM KhachHang kh
            INNER JOIN NguoiDung nd ON kh.maKhachHang = nd.maNguoiDung
            ORDER BY nd.hoTen
        """)

        return render_template('bookings/stats.html',
                               stats=stats or [],
                               customers=customers or [],
                               diemTichLuy=diem_tich_luy,
                               tenKhachHang=ten_kh,
                               filters={
                                   'tuNgay': tu_ngay,
                                   'denNgay': den_ngay,
                                   'nguongDoanhThu': nguong,
                                   'maKhachHang': ma_kh
                               })
    except Error as e:
        error_msg = str(e)
        parts = error_msg.split(': ', 1)
        flash(parts[-1] if len(parts) > 1 else error_msg, 'danger')
        return render_template('bookings/stats.html',
                               stats=[], customers=[],
                               diemTichLuy=None, tenKhachHang=None,
                               filters={})


# ============================================================
# API — Tính giá vé cho ghế + suất chiếu (AJAX)
# Route: GET /api/price/<int:seat_id>/<int:showtime_id>
# Gọi fn_GiaSuatChieuTheoGhe
# ============================================================
@app.route('/api/price/<int:seat_id>/<int:showtime_id>')
def api_get_price(seat_id, showtime_id):
    """API tính giá vé thực tế cho 1 ghế trong 1 suất chiếu."""
    try:
        price = db.call_function('fn_GiaSuatChieuTheoGhe', (seat_id, showtime_id))
        if price is not None and price >= 0:
            return jsonify({'success': True, 'price': float(price)})
        else:
            error_map = {-1: 'Suất chiếu không tồn tại', -2: 'Ghế không tồn tại',
                         -3: 'Ghế không thuộc phòng chiếu này'}
            return jsonify({
                'success': False,
                'error': error_map.get(int(price), 'Lỗi không xác định')
            }), 400
    except Error as e:
        return jsonify({'success': False, 'error': str(e)}), 500


# ============================================================
# CUSTOM JINJA2 FILTERS
# ============================================================
@app.template_filter('format_vnd')
def format_vnd(value):
    """Format số tiền VND: 150000 → 150,000 VND."""
    try:
        return f"{int(value):,} VND".replace(',', '.')
    except (ValueError, TypeError):
        return '0 VND'


@app.template_filter('format_datetime')
def format_datetime(value):
    """Format datetime: 2026-02-28 09:30:00 → 28/02/2026 09:30."""
    if isinstance(value, str):
        value = datetime.fromisoformat(value)
    if isinstance(value, datetime):
        return value.strftime('%d/%m/%Y %H:%M')
    return str(value)


@app.template_filter('format_date')
def format_date_filter(value):
    """Format date: 2026-02-28 → 28/02/2026."""
    if isinstance(value, str):
        value = date.fromisoformat(value)
    if isinstance(value, (date, datetime)):
        return value.strftime('%d/%m/%Y')
    return str(value)


# ============================================================
# ADMIN ENDPOINTS (Database Setup)
# ============================================================
@app.route('/admin/import-sql', methods=['POST'])
def admin_import_sql():
    """Import SQL files vào database (Emergency endpoint)."""
    files = ['schema.sql', 'data.sql', 'triggers.sql', 'procedures_crud.sql', 'procedures_query.sql', 'functions.sql']
    results = {}
    
    for fname in files:
        try:
            result = db.import_sql_file(fname)
            results[fname] = result
        except Exception as e:
            results[fname] = {'success': False, 'error': str(e)}
    
    return jsonify(results)


# ============================================================
# CHẠY ỨNG DỤNG
# ============================================================
if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
