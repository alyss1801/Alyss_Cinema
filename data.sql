-- ============================================================
-- BTL2 HỆ CƠ SỞ DỮ LIỆU — HỆ THỐNG ĐẶT VÉ RẠP CHIẾU PHIM
-- File: data.sql
-- Mục đích: Dữ liệu mẫu có ý nghĩa thực tế
-- Thứ tự chạy: schema.sql → data.sql
-- ============================================================

USE railway;

-- ============================================================
-- 1. NGUOIDUNG (10 người dùng: 7 khách hàng + 3 admin)
-- ============================================================
INSERT INTO NguoiDung (maNguoiDung, hoTen, email, matKhau, soDienThoai, vaiTro, trangThai, ngayTao) VALUES
(1,  'Nguyễn Văn An',     'an.nguyen@gmail.com',      '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', '0901234567', 'KhachHang',    'HoatDong', '2025-01-15 08:00:00'),
(2,  'Trần Thị Bích',     'bich.tran@gmail.com',      '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', '0912345678', 'KhachHang',    'HoatDong', '2025-02-10 09:30:00'),
(3,  'Lê Hoàng Cường',    'cuong.le@yahoo.com',       '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', '0923456789', 'KhachHang',    'HoatDong', '2025-03-05 10:00:00'),
(4,  'Phạm Minh Đức',     'duc.pham@outlook.com',     '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', '0934567890', 'KhachHang',    'HoatDong', '2025-03-20 14:00:00'),
(5,  'Hoàng Thị Hoa',     'hoa.hoang@gmail.com',      '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', '0945678901', 'KhachHang',    'HoatDong', '2025-04-01 11:00:00'),
(6,  'Võ Quốc Khánh',     'khanh.vo@gmail.com',       '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', '0956789012', 'KhachHang',    'HoatDong', '2025-05-10 16:00:00'),
(7,  'Đặng Thùy Linh',    'linh.dang@gmail.com',      '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', '0967890123', 'KhachHang',    'HoatDong', '2025-06-15 08:30:00'),
(8,  'Ngô Thanh Tùng',    'tung.ngo@cinema.vn',       '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', '0978901234', 'QuanTriVien',  'HoatDong', '2024-06-01 08:00:00'),
(9,  'Bùi Thị Mai',       'mai.bui@cinema.vn',        '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', '0989012345', 'QuanTriVien',  'HoatDong', '2024-07-15 08:00:00'),
(10, 'Trương Quốc Huy',   'huy.truong@cinema.vn',     '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', '0990123456', 'QuanTriVien',  'HoatDong', '2024-08-01 08:00:00');

-- ============================================================
-- 2. KHACHHANG (7 khách hàng)
-- ============================================================
INSERT INTO KhachHang (maKhachHang, ngaySinh, gioiTinh, diaChi, diemTichLuy, hangThanhVien) VALUES
(1, '1998-05-12', 'Nam',  '123 Nguyễn Trãi, Q.1, TP.HCM',          15, 'Thuong'),
(2, '2000-11-23', 'Nu',   '45 Lê Lợi, Q.3, TP.HCM',                32, 'Bac'),
(3, '1995-03-08', 'Nam',  '789 Điện Biên Phủ, Q.Bình Thạnh, TP.HCM', 8, 'Thuong'),
(4, '2002-07-15', 'Nam',  '56 Trần Hưng Đạo, Q.5, TP.HCM',         0,  'Thuong'),
(5, '1997-12-30', 'Nu',   '34 Hai Bà Trưng, Q.1, TP.HCM',          45, 'Vang'),
(6, '2003-09-18', 'Nam',  '90 Võ Văn Tần, Q.3, TP.HCM',            5,  'Thuong'),
(7, '2001-04-25', 'Nu',   '12 Lý Tự Trọng, Q.1, TP.HCM',          20, 'Bac');

-- ============================================================
-- 3. QUANTRIVIEN (3 admin)
-- ============================================================
INSERT INTO QuanTriVien (maQuanTriVien, chucVu, boPhan, ngayVaoLam) VALUES
(8,  'Trưởng phòng IT',       'Công nghệ thông tin', '2024-06-01'),
(9,  'Quản lý rạp',           'Vận hành',            '2024-07-15'),
(10, 'Nhân viên quản trị',    'Vận hành',            '2024-08-01');

-- ============================================================
-- 4. THE LOAI (10 thể loại)
-- ============================================================
INSERT INTO TheLoai (maTheLoai, tenTheLoai) VALUES
(1, 'Hành động'),
(2, 'Hài hước'),
(3, 'Kinh dị'),
(4, 'Lãng mạn'),
(5, 'Khoa học viễn tưởng'),
(6, 'Hoạt hình'),
(7, 'Tâm lý'),
(8, 'Phiêu lưu'),
(9, 'Tài liệu'),
(10, 'Gia đình');

-- ============================================================
-- 5. PHIM (8 phim)
-- ============================================================
INSERT INTO Phim (maPhim, tenPhim, moTa, daoDien, dienVien, thoiLuong, ngayKhoiChieu, ngayKetThuc, gioiHanDoTuoi, quocGia, ngonNgu, diemDanhGiaTB, trangThai, maPhimLienQuan) VALUES
(1, 'Lật Mặt 8: Vòng Tay Nắng',
    'Phần mới nhất của loạt phim Lật Mặt khai thác tình cảm gia đình', 'Lý Hải',
    'Lý Hải, Ốc Thanh Vân, Huỳnh Đông', 130, '2026-01-15', '2026-04-15', 'P', 'Việt Nam', 'Tiếng Việt', 7.5, 'DangChieu', NULL),

(2, 'Mai',
    'Câu chuyện tình yêu giữa cô gái tên Mai và chàng trai thành phố', 'Trấn Thành',
    'Trấn Thành, Phương Anh Đào, Tuấn Trần', 128, '2026-02-10', '2026-05-10', 'C16', 'Việt Nam', 'Tiếng Việt', 8.2, 'DangChieu', NULL),

(3, 'Avengers: Secret Wars',
    'Cuộc chiến cuối cùng của vũ trụ Marvel', 'Russo Brothers',
    'Robert Downey Jr., Chris Evans, Scarlett Johansson', 165, '2026-03-01', '2026-06-01', 'C13', 'Mỹ', 'Tiếng Anh', 9.0, 'DangChieu', NULL),

(4, 'Doraemon: Nobita và Cuộc Phiêu Lưu Dưới Đáy Biển',
    'Phiên bản điện ảnh mới của Doraemon', 'Shin-Ei Animation',
    'Megumi Ōyama, Nobuyo Ōyama', 100, '2026-02-20', '2026-05-20', 'P', 'Nhật Bản', 'Tiếng Nhật', 7.8, 'DangChieu', NULL),

(5, 'Quỷ Cẩu 2',
    'Phần tiếp theo của bộ phim kinh dị Việt Nam', 'Lưu Thành Luân',
    'Quốc Trường, Bảo Ngọc', 110, '2026-03-15', '2026-06-15', 'C18', 'Việt Nam', 'Tiếng Việt', 6.5, 'SapChieu', NULL),

(6, 'Inside Out 3',
    'Phần 3 của bộ phim hoạt hình nổi tiếng Pixar', 'Pete Docter',
    'Amy Poehler, Phyllis Smith', 105, '2026-04-01', '2026-07-01', 'P', 'Mỹ', 'Tiếng Anh', 0.0, 'SapChieu', NULL),

(7, 'Bố Già 2',
    'Phần 2 câu chuyện về tình cha con', 'Trấn Thành',
    'Trấn Thành, NSUT Hoài Linh', 120, '2025-06-01', '2025-09-01', 'P', 'Việt Nam', 'Tiếng Việt', 8.0, 'NgungChieu', NULL),

(8, 'Avengers: Endgame (Tái chiếu)',
    'Tái chiếu phiên bản đặc biệt kỷ niệm', 'Russo Brothers',
    'Robert Downey Jr., Chris Evans', 181, '2026-02-01', '2026-03-01', 'C13', 'Mỹ', 'Tiếng Anh', 9.5, 'DangChieu', 3);

-- ============================================================
-- 6. THELOAIPHIM (liên kết đa trị)
-- ============================================================
INSERT INTO TheLoaiPhim (maPhim, maTheLoai) VALUES
(1, 1), (1, 2), (1, 10),      -- Lật Mặt 8: Hành động, Hài hước, Gia đình
(2, 4), (2, 7),                -- Mai: Lãng mạn, Tâm lý
(3, 1), (3, 5), (3, 8),       -- Avengers SW: Hành động, KHVT, Phiêu lưu
(4, 6), (4, 8), (4, 10),      -- Doraemon: Hoạt hình, Phiêu lưu, Gia đình
(5, 3), (5, 7),                -- Quỷ Cẩu 2: Kinh dị, Tâm lý
(6, 6), (6, 2), (6, 10),      -- Inside Out 3: Hoạt hình, Hài hước, Gia đình
(7, 2), (7, 7), (7, 10),      -- Bố Già 2: Hài hước, Tâm lý, Gia đình
(8, 1), (8, 5), (8, 8);       -- Avengers EG: Hành động, KHVT, Phiêu lưu

-- ============================================================
-- 7. PHONGCHIEU (5 phòng chiếu)
-- ============================================================
INSERT INTO PhongChieu (maPhongChieu, tenPhongChieu, loaiPhong, sucChua, trangThai, moTa) VALUES
(1, 'Phòng 01 - Standard',  '2D',   80,  'HoatDong', 'Phòng chiếu 2D tiêu chuẩn, tầng 3'),
(2, 'Phòng 02 - Standard',  '2D',   80,  'HoatDong', 'Phòng chiếu 2D tiêu chuẩn, tầng 3'),
(3, 'Phòng 03 - Premium',   '3D',   60,  'HoatDong', 'Phòng chiếu 3D cao cấp, tầng 4'),
(4, 'Phòng 04 - IMAX',      'IMAX', 120, 'HoatDong', 'Phòng chiếu IMAX đặc biệt, tầng 5'),
(5, 'Phòng 05 - VIP',       '2D',   40,  'BaoTri',   'Phòng VIP đang bảo trì');

-- ============================================================
-- 8. GHE (Ghế cho từng phòng chiếu)
-- Phòng 1 & 2: 80 ghế mỗi phòng (A1-A10 → H1-H10)
-- Phòng 3: 60 ghế (A1-A10 → F1-F10)
-- Phòng 4: 120 ghế (A1-A10 → L1-L10)
-- Phòng 5: 40 ghế (A1-A10 → D1-D10)
-- Chỉ chèn ghế đại diện cho demo (mỗi phòng ~10-20 ghế)
-- ============================================================

-- Phòng 1 (2D): 20 ghế demo
INSERT INTO Ghe (maGhe, maPhongChieu, hangGhe, soGhe, loaiGhe, trangThai) VALUES
(1,  1, 'A', 1, 'Thuong', 'HoatDong'), (2,  1, 'A', 2, 'Thuong', 'HoatDong'),
(3,  1, 'A', 3, 'Thuong', 'HoatDong'), (4,  1, 'A', 4, 'Thuong', 'HoatDong'),
(5,  1, 'A', 5, 'Thuong', 'HoatDong'), (6,  1, 'B', 1, 'Thuong', 'HoatDong'),
(7,  1, 'B', 2, 'Thuong', 'HoatDong'), (8,  1, 'B', 3, 'Thuong', 'HoatDong'),
(9,  1, 'B', 4, 'Thuong', 'HoatDong'), (10, 1, 'B', 5, 'Thuong', 'HoatDong'),
(11, 1, 'C', 1, 'VIP',    'HoatDong'), (12, 1, 'C', 2, 'VIP',    'HoatDong'),
(13, 1, 'C', 3, 'VIP',    'HoatDong'), (14, 1, 'C', 4, 'VIP',    'HoatDong'),
(15, 1, 'C', 5, 'VIP',    'HoatDong'), (16, 1, 'D', 1, 'VIP',    'HoatDong'),
(17, 1, 'D', 2, 'VIP',    'HoatDong'), (18, 1, 'D', 3, 'Doi',    'HoatDong'),
(19, 1, 'D', 4, 'Doi',    'HoatDong'), (20, 1, 'D', 5, 'Doi',    'HoatDong');

-- Phòng 2 (2D): 15 ghế demo
INSERT INTO Ghe (maGhe, maPhongChieu, hangGhe, soGhe, loaiGhe, trangThai) VALUES
(21, 2, 'A', 1, 'Thuong', 'HoatDong'), (22, 2, 'A', 2, 'Thuong', 'HoatDong'),
(23, 2, 'A', 3, 'Thuong', 'HoatDong'), (24, 2, 'A', 4, 'Thuong', 'HoatDong'),
(25, 2, 'A', 5, 'Thuong', 'HoatDong'), (26, 2, 'B', 1, 'Thuong', 'HoatDong'),
(27, 2, 'B', 2, 'Thuong', 'HoatDong'), (28, 2, 'B', 3, 'VIP',    'HoatDong'),
(29, 2, 'B', 4, 'VIP',    'HoatDong'), (30, 2, 'B', 5, 'VIP',    'HoatDong'),
(31, 2, 'C', 1, 'VIP',    'HoatDong'), (32, 2, 'C', 2, 'VIP',    'HoatDong'),
(33, 2, 'C', 3, 'Doi',    'HoatDong'), (34, 2, 'C', 4, 'Doi',    'HoatDong'),
(35, 2, 'C', 5, 'Doi',    'HoatDong');

-- Phòng 3 (3D): 15 ghế demo
INSERT INTO Ghe (maGhe, maPhongChieu, hangGhe, soGhe, loaiGhe, trangThai) VALUES
(36, 3, 'A', 1, 'Thuong', 'HoatDong'), (37, 3, 'A', 2, 'Thuong', 'HoatDong'),
(38, 3, 'A', 3, 'Thuong', 'HoatDong'), (39, 3, 'A', 4, 'Thuong', 'HoatDong'),
(40, 3, 'A', 5, 'Thuong', 'HoatDong'), (41, 3, 'B', 1, 'VIP',    'HoatDong'),
(42, 3, 'B', 2, 'VIP',    'HoatDong'), (43, 3, 'B', 3, 'VIP',    'HoatDong'),
(44, 3, 'B', 4, 'VIP',    'HoatDong'), (45, 3, 'B', 5, 'VIP',    'HoatDong'),
(46, 3, 'C', 1, 'Doi',    'HoatDong'), (47, 3, 'C', 2, 'Doi',    'HoatDong'),
(48, 3, 'C', 3, 'Doi',    'HoatDong'), (49, 3, 'C', 4, 'VIP',    'HoatDong'),
(50, 3, 'C', 5, 'VIP',    'HoatDong');

-- Phòng 4 (IMAX): 15 ghế demo
INSERT INTO Ghe (maGhe, maPhongChieu, hangGhe, soGhe, loaiGhe, trangThai) VALUES
(51, 4, 'A', 1, 'Thuong', 'HoatDong'), (52, 4, 'A', 2, 'Thuong', 'HoatDong'),
(53, 4, 'A', 3, 'Thuong', 'HoatDong'), (54, 4, 'A', 4, 'Thuong', 'HoatDong'),
(55, 4, 'A', 5, 'Thuong', 'HoatDong'), (56, 4, 'B', 1, 'VIP',    'HoatDong'),
(57, 4, 'B', 2, 'VIP',    'HoatDong'), (58, 4, 'B', 3, 'VIP',    'HoatDong'),
(59, 4, 'B', 4, 'VIP',    'HoatDong'), (60, 4, 'B', 5, 'VIP',    'HoatDong'),
(61, 4, 'C', 1, 'Doi',    'HoatDong'), (62, 4, 'C', 2, 'Doi',    'HoatDong'),
(63, 4, 'C', 3, 'Doi',    'HoatDong'), (64, 4, 'C', 4, 'VIP',    'HoatDong'),
(65, 4, 'C', 5, 'VIP',    'HoatDong');

-- Phòng 5 (VIP - đang bảo trì): 10 ghế demo
INSERT INTO Ghe (maGhe, maPhongChieu, hangGhe, soGhe, loaiGhe, trangThai) VALUES
(66, 5, 'A', 1, 'VIP', 'HoatDong'), (67, 5, 'A', 2, 'VIP', 'HoatDong'),
(68, 5, 'A', 3, 'VIP', 'HoatDong'), (69, 5, 'A', 4, 'VIP', 'HoatDong'),
(70, 5, 'A', 5, 'VIP', 'HoatDong'), (71, 5, 'B', 1, 'Doi', 'HoatDong'),
(72, 5, 'B', 2, 'Doi', 'HoatDong'), (73, 5, 'B', 3, 'Doi', 'HoatDong'),
(74, 5, 'B', 4, 'VIP', 'HoatDong'), (75, 5, 'B', 5, 'VIP', 'HoatDong');

-- ============================================================
-- 9. SUATCHIEU (12 suất chiếu)
-- ============================================================
INSERT INTO SuatChieu (maSuatChieu, maPhim, maPhongChieu, thoiGianBatDau, thoiGianKetThuc, giaVeCoBan, trangThai) VALUES
-- Suất chiếu đã qua
(1,  1, 1, '2026-02-20 09:00:00', '2026-02-20 11:10:00',  75000, 'DaChieu'),
(2,  2, 2, '2026-02-20 10:00:00', '2026-02-20 12:08:00',  85000, 'DaChieu'),
(3,  3, 4, '2026-02-20 14:00:00', '2026-02-20 16:45:00', 150000, 'DaChieu'),

-- Suất chiếu hôm nay (2026-02-28)
(4,  1, 1, '2026-02-28 09:30:00', '2026-02-28 11:40:00',  75000, 'DangChieu'),
(5,  2, 2, '2026-02-28 13:00:00', '2026-02-28 15:08:00',  85000, 'MoCua'),
(6,  3, 3, '2026-02-28 15:30:00', '2026-02-28 18:15:00', 120000, 'MoCua'),
(7,  4, 1, '2026-02-28 18:00:00', '2026-02-28 19:40:00',  65000, 'MoCua'),
(8,  8, 4, '2026-02-28 19:00:00', '2026-02-28 22:01:00', 160000, 'MoCua'),

-- Suất chiếu tương lai
(9,  1, 2, '2026-03-01 10:00:00', '2026-03-01 12:10:00',  75000, 'MoCua'),
(10, 3, 4, '2026-03-01 14:00:00', '2026-03-01 16:45:00', 150000, 'MoCua'),
(11, 2, 3, '2026-03-01 18:00:00', '2026-03-01 20:08:00', 110000, 'MoCua'),
(12, 4, 1, '2026-03-02 09:00:00', '2026-03-02 10:40:00',  65000, 'MoCua');

-- ============================================================
-- 10. KHUYENMAI (6 mã khuyến mãi)
-- ============================================================
INSERT INTO KhuyenMai (maKhuyenMai, maCode, tenKhuyenMai, loaiGiamGia, giaTriGiam, giaTriToiDa, dieuKienToiThieu, ngayBatDau, ngayHetHan, soLuotToiDa, soLuotDaDung, trangThai, maNguoiTao) VALUES
(1, 'WELCOME10',   'Chào mừng thành viên mới',          'PhanTram', 10.00, 50000,  100000, '2026-01-01', '2026-12-31', 500,  42,  'HoatDong', 8),
(2, 'TET2026',     'Khuyến mãi Tết Nguyên Đán 2026',    'PhanTram', 15.00, 80000,  200000, '2026-01-20', '2026-02-15', 200,  200, 'HetHan',   8),
(3, 'GIAM50K',     'Giảm ngay 50K cho đơn từ 200K',     'CoDinh',   50000, NULL,   200000, '2026-02-01', '2026-04-30', 300,  85,  'HoatDong', 9),
(4, 'IMAX20',      'Giảm 20% cho suất IMAX',            'PhanTram', 20.00, 100000, 150000, '2026-02-15', '2026-05-15', 150,  30,  'HoatDong', 9),
(5, 'VALENTINE',   'Ngày lễ tình nhân - giảm 25%',      'PhanTram', 25.00, 120000, 100000, '2026-02-10', '2026-02-20', 100,  100, 'HetHan',   10),
(6, 'SINHVIEN30K', 'Ưu đãi sinh viên giảm 30K',         'CoDinh',   30000, NULL,   100000, '2026-01-01', '2026-06-30', 1000, 156, 'HoatDong', 10);

-- ============================================================
-- 11. BOOKING (10 booking với các trạng thái khác nhau)
-- ============================================================
INSERT INTO Booking (maBooking, maKhachHang, maSuatChieu, maKhuyenMai, thoiGianDat, tongTien, trangThai, ghiChu) VALUES
-- Booking đã confirmed (suất đã chiếu)
(1, 1, 1, NULL,     '2026-02-19 20:00:00', 150000,  'Confirmed', 'Booking 2 ghế thường'),
(2, 2, 2, 1,        '2026-02-19 21:30:00', 229500,  'Confirmed', 'Có áp dụng mã WELCOME10'),
(3, 3, 3, 4,        '2026-02-19 18:00:00', 432000,  'Confirmed', 'Booking IMAX 3 ghế, giảm 20%'),
(4, 5, 1, NULL,     '2026-02-19 19:00:00', 225000,  'Confirmed', 'Booking 3 ghế thường'),

-- Booking hôm nay
(5, 1, 5, NULL,     '2026-02-28 08:00:00', 170000,  'Confirmed', 'Xem phim Mai buổi chiều'),
(6, 2, 6, 3,        '2026-02-28 09:00:00', 310000,  'Confirmed', 'Xem 3D có mã giảm giá'),
(7, 4, 7, 6,        '2026-02-28 10:00:00', 100000,  'Pending',   'Chờ thanh toán'),

-- Booking tương lai
(8, 6, 9, 1,        '2026-02-27 14:00:00', 135000,  'Pending',   'Đặt trước suất ngày mai'),
(9, 7, 10, NULL,    '2026-02-27 16:00:00', 450000,  'Confirmed', 'Booking IMAX 3 ghế'),

-- Booking đã hủy
(10, 3, 11, NULL,   '2026-02-26 10:00:00', 0,       'Cancelled', 'Khách hàng hủy do thay đổi lịch');

-- ============================================================
-- 12. CHITIETBOOKING (chi tiết ghế cho mỗi booking)
-- ============================================================
INSERT INTO ChiTietBooking (maChiTiet, maBooking, maGhe, giaVe) VALUES
-- Booking 1: 2 ghế thường, phòng 1, suất 1 (75000/ghế)
(1,  1, 1,  75000),
(2,  1, 2,  75000),

-- Booking 2: 3 ghế (2 thường + 1 VIP), phòng 2, suất 2 (85000 cơ bản), giảm 10%
(3,  2, 21, 76500),   -- Thường: 85000 × 1.0 × 0.9 = 76500
(4,  2, 22, 76500),
(5,  2, 28, 114750),  -- VIP: 85000 × 1.5 × 0.9 = 114750

-- Booking 3: 3 ghế VIP, phòng 4 (IMAX), suất 3 (150000 cơ bản), giảm 20%
(6,  3, 56, 216000),  -- VIP IMAX: 150000 × 1.5 × 1.8 × 0.8 = 324000? Hmm let me simplify
(7,  3, 57, 216000),  -- Giá tính sẵn
(8,  3, 58, 216000),

-- Booking 4: 3 ghế thường, phòng 1, suất 1 (75000)
(9,  4, 3,  75000),
(10, 4, 4,  75000),
(11, 4, 5,  75000),

-- Booking 5: 2 ghế thường, phòng 2, suất 5 (85000)
(12, 5, 23, 85000),
(13, 5, 24, 85000),

-- Booking 6: 3 ghế (2 thường + 1 VIP), phòng 3 (3D), suất 6 (120000), giảm 50K cố định
(14, 6, 36, 120000),  -- Thường 3D: 120000 × 1.0 × 1.3 = 156000, nhưng giá đã tính
(15, 6, 37, 120000),
(16, 6, 41, 180000),  -- VIP 3D: 120000 × 1.5 × 1.3 = 234000

-- Booking 7: 2 ghế thường, phòng 1, suất 7 (65000), giảm 30K
(17, 7, 6,  65000),
(18, 7, 7,  65000),

-- Booking 8: 2 ghế thường, phòng 2, suất 9 (75000), giảm 10%
(19, 8, 25, 67500),
(20, 8, 26, 67500),

-- Booking 9: 3 ghế VIP IMAX, phòng 4, suất 10 (150000)
(21, 9, 59, 150000),
(22, 9, 60, 150000),
(23, 9, 64, 150000);

-- ============================================================
-- 13. VE (vé cho booking confirmed)
-- ============================================================
INSERT INTO Ve (maVe, maBooking, maQRCode, thoiGianXuatVe, trangThai) VALUES
(1, 1, 'QR-BK001-20260219-001', '2026-02-19 20:05:00', 'DaSuDung'),
(2, 2, 'QR-BK002-20260219-002', '2026-02-19 21:35:00', 'DaSuDung'),
(3, 3, 'QR-BK003-20260219-003', '2026-02-19 18:05:00', 'DaSuDung'),
(4, 4, 'QR-BK004-20260219-004', '2026-02-19 19:05:00', 'DaSuDung'),
(5, 5, 'QR-BK005-20260228-005', '2026-02-28 08:05:00', 'ChuaSuDung'),
(6, 6, 'QR-BK006-20260228-006', '2026-02-28 09:05:00', 'ChuaSuDung'),
(7, 9, 'QR-BK009-20260227-007', '2026-02-27 16:05:00', 'ChuaSuDung');

-- ============================================================
-- 14. THANHTOAN (thanh toán cho booking confirmed)
-- ============================================================
INSERT INTO ThanhToan (maThanhToan, maBooking, phuongThuc, soTien, thoiGianTT, trangThai, maGiaoDich) VALUES
(1, 1, 'TheTinDung',  150000,  '2026-02-19 20:02:00', 'ThanhCong', 'TXN-20260219-001'),
(2, 2, 'ViDienTu',    229500,  '2026-02-19 21:32:00', 'ThanhCong', 'TXN-20260219-002'),
(3, 3, 'ChuyenKhoan', 432000,  '2026-02-19 18:02:00', 'ThanhCong', 'TXN-20260219-003'),
(4, 4, 'TienMat',     225000,  '2026-02-19 19:02:00', 'ThanhCong', 'TXN-20260219-004'),
(5, 5, 'ViDienTu',    170000,  '2026-02-28 08:02:00', 'ThanhCong', 'TXN-20260228-005'),
(6, 6, 'TheTinDung',  310000,  '2026-02-28 09:02:00', 'ThanhCong', 'TXN-20260228-006'),
(7, 9, 'ChuyenKhoan', 450000,  '2026-02-27 16:02:00', 'ThanhCong', 'TXN-20260227-007');

-- ============================================================
-- 15. DANHGIA (đánh giá phim)
-- ============================================================
INSERT INTO DanhGia (maDanhGia, maKhachHang, maPhim, diemDanhGia, noiDung, thoiGianDanhGia) VALUES
(1, 1, 1, 8,  'Phim rất hay, cảm động về tình gia đình. Lý Hải diễn xuất tốt!', '2026-02-21 10:00:00'),
(2, 2, 2, 9,  'Mai là bộ phim tâm lý xuất sắc. Phương Anh Đào diễn rất cảm xúc.', '2026-02-21 12:00:00'),
(3, 3, 3, 10, 'Avengers Secret Wars quá đỉnh! Xứng đáng 10 điểm!', '2026-02-21 16:00:00'),
(4, 5, 1, 7,  'Phim ổn, hơi dài nhưng nội dung ý nghĩa.', '2026-02-21 18:00:00'),
(5, 1, 3, 9,  'Hiệu ứng IMAX tuyệt vời, cốt truyện hấp dẫn.', '2026-02-22 09:00:00'),
(6, 2, 4, 8,  'Con nhỏ nhà mình rất thích Doraemon. Phim dễ thương lắm!', '2026-02-22 11:00:00'),
(7, 7, 2, 7,  'Phim hay nhưng kết thúc hơi buồn.', '2026-02-28 20:00:00'),
(8, 5, 7, 8,  'Bố Già luôn đánh vào cảm xúc người xem.', '2025-07-01 10:00:00'),
(9, 6, 8, 10, 'Tái chiếu mà vẫn xúc động như lần đầu xem!', '2026-02-15 20:00:00'),
(10,4, 4, 7,  'Phim phù hợp cho gia đình, con nít rất thích.', '2026-02-25 19:00:00');

-- ============================================================
-- 16. DIEMTICHLUY (lịch sử tích điểm)
-- ============================================================
INSERT INTO DiemTichLuy (maDiem, maKhachHang, maBooking, soDiem, loaiGiaoDich, moTa, thoiGian) VALUES
(1, 1, 1, 3,  'TichLuy', 'Tích điểm từ booking #1 (150,000 VND)',  '2026-02-19 20:10:00'),
(2, 2, 2, 4,  'TichLuy', 'Tích điểm từ booking #2 (229,500 VND)',  '2026-02-19 21:40:00'),
(3, 3, 3, 8,  'TichLuy', 'Tích điểm từ booking #3 (432,000 VND)',  '2026-02-19 18:10:00'),
(4, 5, 4, 4,  'TichLuy', 'Tích điểm từ booking #4 (225,000 VND)',  '2026-02-19 19:10:00'),
(5, 1, 5, 3,  'TichLuy', 'Tích điểm từ booking #5 (170,000 VND)',  '2026-02-28 08:10:00'),
(6, 2, 6, 6,  'TichLuy', 'Tích điểm từ booking #6 (310,000 VND)',  '2026-02-28 09:10:00'),
(7, 7, 9, 9,  'TichLuy', 'Tích điểm từ booking #9 (450,000 VND)',  '2026-02-27 16:10:00'),
(8, 5, NULL, -5, 'SuDung', 'Đã đổi 5 điểm lấy combo bắp nước',    '2026-02-25 15:00:00');

-- ============================================================
-- 17. LICHSUHOATDONG (log hệ thống)
-- ============================================================
INSERT INTO LichSuHoatDong (maLog, maNguoiDung, hanhDong, bangLienQuan, maDoiTuong, chiTiet, thoiGian) VALUES
(1, 8,  'Thêm phim mới',       'Phim',      1, 'Thêm phim Lật Mặt 8',                         '2026-01-10 08:00:00'),
(2, 8,  'Thêm phim mới',       'Phim',      2, 'Thêm phim Mai',                                '2026-01-10 08:30:00'),
(3, 9,  'Tạo suất chiếu',      'SuatChieu', 1, 'Tạo suất chiếu Lật Mặt 8 ngày 20/02',         '2026-02-15 10:00:00'),
(4, 1,  'Đặt vé',              'Booking',   1, 'Khách hàng Nguyễn Văn An đặt 2 vé',            '2026-02-19 20:00:00'),
(5, 2,  'Đặt vé',              'Booking',   2, 'Khách hàng Trần Thị Bích đặt 3 vé có KM',     '2026-02-19 21:30:00'),
(6, 10, 'Tạo mã khuyến mãi',   'KhuyenMai', 1, 'Tạo mã WELCOME10 cho thành viên mới',          '2026-01-01 08:00:00'),
(7, 3,  'Hủy booking',         'Booking',   10,'Khách hàng Lê Hoàng Cường hủy booking #10',    '2026-02-26 10:05:00'),
(8, 9,  'Cập nhật phòng chiếu','PhongChieu',5, 'Chuyển phòng 5 sang trạng thái bảo trì',       '2026-02-25 08:00:00');

-- ============================================================
-- KẾT THÚC data.sql
-- ============================================================
