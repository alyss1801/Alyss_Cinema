-- ============================================================
-- BTL2 HỆ CƠ SỞ DỮ LIỆU — HỆ THỐNG ĐẶT VÉ RẠP CHIẾU PHIM
-- File: schema.sql
-- Mục đích: Tạo database và toàn bộ bảng với ràng buộc
-- ============================================================

DROP DATABASE IF EXISTS railway;
CREATE DATABASE railway
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE railway;

-- ============================================================
-- 1. BẢNG NGUOIDUNG (Superclass — tài khoản hệ thống)
-- Phân loại: Khách hàng / Quản trị viên
-- ============================================================
CREATE TABLE NguoiDung (
    maNguoiDung   INT AUTO_INCREMENT PRIMARY KEY,
    hoTen         VARCHAR(100)    NOT NULL,
    email         VARCHAR(150)    NOT NULL UNIQUE,
    matKhau       VARCHAR(255)    NOT NULL,
    soDienThoai   VARCHAR(15)     NOT NULL,
    vaiTro        ENUM('KhachHang', 'QuanTriVien') NOT NULL DEFAULT 'KhachHang',
    trangThai     ENUM('HoatDong', 'BiKhoa')       NOT NULL DEFAULT 'HoatDong',
    ngayTao       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- RC9: Số điện thoại 10 chữ số, bắt đầu bằng 0
    CONSTRAINT chk_SoDienThoai CHECK (soDienThoai REGEXP '^0[0-9]{9}$'),
    -- RC10: Email phải chứa '@' và '.'
    CONSTRAINT chk_Email CHECK (email LIKE '%@%.%')
) COMMENT = 'Bảng superclass — tài khoản người dùng hệ thống';

-- ============================================================
-- 2. BẢNG KHACHHANG (Subclass của NguoiDung)
-- ============================================================
CREATE TABLE KhachHang (
    maKhachHang   INT PRIMARY KEY,
    ngaySinh      DATE            NOT NULL,
    gioiTinh      ENUM('Nam', 'Nu', 'Khac') NOT NULL DEFAULT 'Khac',
    diaChi        VARCHAR(255)    DEFAULT NULL,
    diemTichLuy   INT             NOT NULL DEFAULT 0  COMMENT 'Thuộc tính DẪN XUẤT — tính từ lịch sử giao dịch',
    soDuVi        DECIMAL(15,2)   NOT NULL DEFAULT 5000000 COMMENT 'Số dư ví ảo của khách hàng',
    hangThanhVien ENUM('Thuong', 'Bac', 'Vang', 'KimCuong') NOT NULL DEFAULT 'Thuong',

    CONSTRAINT fk_KhachHang_NguoiDung
        FOREIGN KEY (maKhachHang) REFERENCES NguoiDung(maNguoiDung)
        ON DELETE CASCADE ON UPDATE CASCADE
) COMMENT = 'Subclass KhachHang — thông tin riêng của khách hàng';

-- ============================================================
-- 3. BẢNG QUANTRIVIEN (Subclass của NguoiDung)
-- ============================================================
CREATE TABLE QuanTriVien (
    maQuanTriVien INT PRIMARY KEY,
    chucVu        VARCHAR(100)    NOT NULL DEFAULT 'Admin',
    boPhan        VARCHAR(100)    DEFAULT NULL,
    ngayVaoLam    DATE            NOT NULL,

    CONSTRAINT fk_QuanTriVien_NguoiDung
        FOREIGN KEY (maQuanTriVien) REFERENCES NguoiDung(maNguoiDung)
        ON DELETE CASCADE ON UPDATE CASCADE
) COMMENT = 'Subclass QuanTriVien — thông tin riêng của admin';

-- ============================================================
-- 4. BẢNG PHIM (Thông tin phim)
-- ============================================================
CREATE TABLE Phim (
    maPhim          INT AUTO_INCREMENT PRIMARY KEY,
    tenPhim         VARCHAR(200)    NOT NULL,
    moTa            TEXT            DEFAULT NULL,
    daoDien         VARCHAR(100)    DEFAULT NULL,
    dienVien        VARCHAR(500)    DEFAULT NULL,
    thoiLuong       INT             NOT NULL COMMENT 'Thời lượng phim (phút)',
    ngayKhoiChieu   DATE            NOT NULL,
    ngayKetThuc     DATE            DEFAULT NULL,
    gioiHanDoTuoi   ENUM('P', 'C13', 'C16', 'C18') NOT NULL DEFAULT 'P'
        COMMENT 'P: mọi lứa tuổi, C13: 13+, C16: 16+, C18: 18+',
    posterURL       VARCHAR(500)    DEFAULT NULL,
    trailerURL      VARCHAR(500)    DEFAULT NULL,
    quocGia         VARCHAR(100)    DEFAULT 'Việt Nam',
    ngonNgu         VARCHAR(50)     DEFAULT 'Tiếng Việt',
    diemDanhGiaTB   DECIMAL(3,1)    DEFAULT 0.0 COMMENT 'Thuộc tính DẪN XUẤT — AVG từ bảng DanhGia',
    trangThai       ENUM('DangChieu', 'SapChieu', 'NgungChieu') NOT NULL DEFAULT 'SapChieu',

    -- Mối liên kết đệ quy: phim liên quan / phim gốc (sequel / prequel)
    maPhimLienQuan  INT DEFAULT NULL,

    CONSTRAINT chk_ThoiLuong CHECK (thoiLuong > 0 AND thoiLuong <= 600),
    CONSTRAINT chk_DiemDanhGiaTB CHECK (diemDanhGiaTB >= 0 AND diemDanhGiaTB <= 10),
    CONSTRAINT fk_Phim_PhimLienQuan
        FOREIGN KEY (maPhimLienQuan) REFERENCES Phim(maPhim)
        ON DELETE SET NULL ON UPDATE CASCADE
) COMMENT = 'Bảng Phim — thông tin phim chiếu tại rạp (có liên kết đệ quy)';

-- ============================================================
-- 5. BẢNG THELOAIPHIM (Bảng đa trị — 1 phim nhiều thể loại)
-- Mối liên kết N:M giữa Phim và Thể loại
-- ============================================================
CREATE TABLE TheLoai (
    maTheLoai   INT AUTO_INCREMENT PRIMARY KEY,
    tenTheLoai  VARCHAR(50) NOT NULL UNIQUE
) COMMENT = 'Danh mục thể loại phim';

CREATE TABLE TheLoaiPhim (
    maPhim      INT NOT NULL,
    maTheLoai   INT NOT NULL,
    PRIMARY KEY (maPhim, maTheLoai),

    CONSTRAINT fk_TheLoaiPhim_Phim
        FOREIGN KEY (maPhim) REFERENCES Phim(maPhim)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_TheLoaiPhim_TheLoai
        FOREIGN KEY (maTheLoai) REFERENCES TheLoai(maTheLoai)
        ON DELETE CASCADE ON UPDATE CASCADE
) COMMENT = 'Bảng đa trị — liên kết N:M giữa Phim và TheLoai';

-- ============================================================
-- 6. BẢNG PHONGCHIEU (Phòng chiếu phim)
-- ============================================================
CREATE TABLE PhongChieu (
    maPhongChieu    INT AUTO_INCREMENT PRIMARY KEY,
    tenPhongChieu   VARCHAR(50)  NOT NULL UNIQUE,
    loaiPhong       ENUM('2D', '3D', 'IMAX') NOT NULL DEFAULT '2D',
    sucChua         INT          NOT NULL DEFAULT 0 COMMENT 'Thuộc tính DẪN XUẤT — tổng ghế trong phòng',
    trangThai       ENUM('HoatDong', 'BaoTri', 'DongCua') NOT NULL DEFAULT 'HoatDong',
    moTa            VARCHAR(255) DEFAULT NULL,

    CONSTRAINT chk_SucChua CHECK (sucChua >= 0)
) COMMENT = 'Bảng PhongChieu — phòng chiếu phim trong rạp';

-- ============================================================
-- 7. BẢNG GHE (Thực thể YẾU — phụ thuộc PhongChieu)
-- Khóa chính: maPhongChieu + maGhe (hoặc dùng surrogate key + UNIQUE)
-- ============================================================
CREATE TABLE Ghe (
    maGhe           INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Surrogate key cho dễ reference',
    maPhongChieu    INT         NOT NULL,
    hangGhe         CHAR(1)     NOT NULL COMMENT 'A, B, C, ...',
    soGhe           INT         NOT NULL COMMENT 'Số ghế trong hàng: 1, 2, 3...',
    loaiGhe         ENUM('Thuong', 'VIP', 'Doi') NOT NULL DEFAULT 'Thuong',
    trangThai       ENUM('HoatDong', 'Hong', 'BaoTri') NOT NULL DEFAULT 'HoatDong',

    CONSTRAINT uq_Ghe_PhongChieu UNIQUE (maPhongChieu, hangGhe, soGhe),
    CONSTRAINT fk_Ghe_PhongChieu
        FOREIGN KEY (maPhongChieu) REFERENCES PhongChieu(maPhongChieu)
        ON DELETE CASCADE ON UPDATE CASCADE
) COMMENT = 'Thực thể YẾU Ghe — ghế ngồi trong phòng chiếu, định danh qua PhongChieu + hàng + số ghế';

-- ============================================================
-- 8. BẢNG SUATCHIEU (Suất chiếu phim)
-- ============================================================
CREATE TABLE SuatChieu (
    maSuatChieu     INT AUTO_INCREMENT PRIMARY KEY,
    maPhim          INT         NOT NULL,
    maPhongChieu    INT         NOT NULL,
    thoiGianBatDau  DATETIME    NOT NULL,
    thoiGianKetThuc DATETIME    NOT NULL,
    giaVeCoBan      DECIMAL(12,0) NOT NULL DEFAULT 75000 COMMENT 'Giá vé cơ bản (VND)',
    trangThai       ENUM('MoCua', 'DangChieu', 'DaChieu', 'HuyBo') NOT NULL DEFAULT 'MoCua',

    -- RC1: Giờ kết thúc phải sau giờ bắt đầu
    CONSTRAINT chk_ThoiGian CHECK (thoiGianKetThuc > thoiGianBatDau),
    CONSTRAINT chk_GiaVe CHECK (giaVeCoBan > 0),

    CONSTRAINT fk_SuatChieu_Phim
        FOREIGN KEY (maPhim) REFERENCES Phim(maPhim)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_SuatChieu_PhongChieu
        FOREIGN KEY (maPhongChieu) REFERENCES PhongChieu(maPhongChieu)
        ON DELETE CASCADE ON UPDATE CASCADE
) COMMENT = 'Bảng SuatChieu — suất chiếu phim (phim + phòng + thời gian)';

-- ============================================================
-- 9. BẢNG KHUYENMAI (Mã khuyến mãi / giảm giá)
-- ============================================================
CREATE TABLE KhuyenMai (
    maKhuyenMai     INT AUTO_INCREMENT PRIMARY KEY,
    maCode          VARCHAR(50)     NOT NULL UNIQUE COMMENT 'Mã code khuyến mãi (VD: SUMMER2026)',
    tenKhuyenMai    VARCHAR(200)    NOT NULL,
    loaiGiamGia     ENUM('PhanTram', 'CoDinh') NOT NULL DEFAULT 'PhanTram',
    giaTriGiam      DECIMAL(12,2)   NOT NULL COMMENT 'Giá trị giảm: % hoặc số tiền cố định',
    giaTriToiDa     DECIMAL(12,0)   DEFAULT NULL COMMENT 'Giảm tối đa (áp dụng cho loại %)',
    dieuKienToiThieu DECIMAL(12,0)  DEFAULT 0 COMMENT 'Đơn tối thiểu để áp dụng',
    ngayBatDau      DATE            NOT NULL,
    ngayHetHan      DATE            NOT NULL,
    soLuotToiDa     INT             NOT NULL DEFAULT 100 COMMENT 'Số lượt sử dụng tối đa',
    soLuotDaDung    INT             NOT NULL DEFAULT 0,
    trangThai       ENUM('HoatDong', 'HetHan', 'TamNgung') NOT NULL DEFAULT 'HoatDong',

    -- Quản trị viên tạo KM
    maNguoiTao      INT DEFAULT NULL,

    CONSTRAINT chk_GiaTriGiam CHECK (giaTriGiam > 0),
    CONSTRAINT chk_SoLuot CHECK (soLuotDaDung >= 0 AND soLuotDaDung <= soLuotToiDa),
    -- RC7: Số lượt sử dụng không vượt quá tối đa (đã check ở trên)
    CONSTRAINT chk_NgayKM CHECK (ngayHetHan >= ngayBatDau),

    CONSTRAINT fk_KhuyenMai_NguoiTao
        FOREIGN KEY (maNguoiTao) REFERENCES NguoiDung(maNguoiDung)
        ON DELETE SET NULL ON UPDATE CASCADE
) COMMENT = 'Bảng KhuyenMai — mã khuyến mãi / giảm giá';

-- ============================================================
-- 10. BẢNG BOOKING (Đơn đặt vé — BẢNG TRUNG TÂM CRUD)
-- ============================================================
CREATE TABLE Booking (
    maBooking       INT AUTO_INCREMENT PRIMARY KEY,
    maKhachHang     INT         NOT NULL,
    maSuatChieu     INT         NOT NULL,
    maKhuyenMai     INT         DEFAULT NULL,
    thoiGianDat     DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    tongTien        DECIMAL(12,0) NOT NULL DEFAULT 0 COMMENT 'Thuộc tính DẪN XUẤT — tổng tiền các ghế × hệ số',
    trangThai       ENUM('Pending', 'Confirmed', 'Cancelled') NOT NULL DEFAULT 'Pending',
    ghiChu          VARCHAR(500) DEFAULT NULL,

    CONSTRAINT fk_Booking_KhachHang
        FOREIGN KEY (maKhachHang) REFERENCES KhachHang(maKhachHang)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_Booking_SuatChieu
        FOREIGN KEY (maSuatChieu) REFERENCES SuatChieu(maSuatChieu)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_Booking_KhuyenMai
        FOREIGN KEY (maKhuyenMai) REFERENCES KhuyenMai(maKhuyenMai)
        ON DELETE SET NULL ON UPDATE CASCADE
) COMMENT = 'Bảng Booking — đơn đặt vé (BẢNG TRUNG TÂM CRUD)';

-- ============================================================
-- 11. BẢNG CHITIETBOOKING (Thực thể YẾU của Booking)
-- Mỗi dòng = 1 ghế trong 1 booking
-- ============================================================
CREATE TABLE ChiTietBooking (
    maChiTiet       INT AUTO_INCREMENT PRIMARY KEY,
    maBooking       INT         NOT NULL,
    maGhe           INT         NOT NULL,
    giaVe           DECIMAL(12,0) NOT NULL DEFAULT 0 COMMENT 'Giá vé thực tế cho ghế này',

    CONSTRAINT uq_ChiTiet_Booking_Ghe UNIQUE (maBooking, maGhe),

    CONSTRAINT fk_ChiTietBooking_Booking
        FOREIGN KEY (maBooking) REFERENCES Booking(maBooking)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_ChiTietBooking_Ghe
        FOREIGN KEY (maGhe) REFERENCES Ghe(maGhe)
        ON DELETE CASCADE ON UPDATE CASCADE
) COMMENT = 'Thực thể YẾU ChiTietBooking — chi tiết ghế trong đơn đặt vé';

-- ============================================================
-- 12. BẢNG VE (Vé sau khi thanh toán thành công)
-- Liên kết 1:1 với Booking
-- ============================================================
CREATE TABLE Ve (
    maVe            INT AUTO_INCREMENT PRIMARY KEY,
    maBooking       INT         NOT NULL UNIQUE COMMENT 'Liên kết 1:1 với Booking',
    maQRCode        VARCHAR(255) NOT NULL UNIQUE COMMENT 'Mã QR code duy nhất',
    thoiGianXuatVe  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    trangThai       ENUM('ChuaSuDung', 'DaSuDung', 'HetHan', 'DaHuy') NOT NULL DEFAULT 'ChuaSuDung',

    CONSTRAINT fk_Ve_Booking
        FOREIGN KEY (maBooking) REFERENCES Booking(maBooking)
        ON DELETE CASCADE ON UPDATE CASCADE
) COMMENT = 'Bảng Ve — vé điện tử sau khi thanh toán thành công (1:1 với Booking)';

-- ============================================================
-- 13. BẢNG THANHTOAN (Thông tin thanh toán)
-- ============================================================
CREATE TABLE ThanhToan (
    maThanhToan     INT AUTO_INCREMENT PRIMARY KEY,
    maBooking       INT         NOT NULL,
    phuongThuc      ENUM('TienMat', 'TheTinDung', 'ViDienTu', 'ChuyenKhoan') NOT NULL DEFAULT 'TienMat',
    soTien          DECIMAL(12,0) NOT NULL,
    thoiGianTT      DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    trangThai       ENUM('ThanhCong', 'ThatBai', 'DangXuLy', 'HoanTien') NOT NULL DEFAULT 'DangXuLy',
    maGiaoDich      VARCHAR(100) DEFAULT NULL COMMENT 'Mã giao dịch từ cổng thanh toán',

    CONSTRAINT chk_SoTien CHECK (soTien >= 0),
    CONSTRAINT fk_ThanhToan_Booking
        FOREIGN KEY (maBooking) REFERENCES Booking(maBooking)
        ON DELETE CASCADE ON UPDATE CASCADE
) COMMENT = 'Bảng ThanhToan — thông tin thanh toán cho booking';

-- ============================================================
-- 14. BẢNG DANHGIA (Đánh giá phim của khách hàng)
-- ============================================================
CREATE TABLE DanhGia (
    maDanhGia       INT AUTO_INCREMENT PRIMARY KEY,
    maKhachHang     INT         NOT NULL,
    maPhim          INT         NOT NULL,
    diemDanhGia     INT         NOT NULL COMMENT 'Điểm từ 1 đến 10',
    noiDung         TEXT        DEFAULT NULL,
    thoiGianDanhGia DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- RC5: Điểm đánh giá phải trong khoảng 1–10
    CONSTRAINT chk_DiemDanhGia CHECK (diemDanhGia >= 1 AND diemDanhGia <= 10),
    -- Mỗi khách hàng chỉ đánh giá 1 phim 1 lần
    CONSTRAINT uq_DanhGia_KH_Phim UNIQUE (maKhachHang, maPhim),

    CONSTRAINT fk_DanhGia_KhachHang
        FOREIGN KEY (maKhachHang) REFERENCES KhachHang(maKhachHang)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_DanhGia_Phim
        FOREIGN KEY (maPhim) REFERENCES Phim(maPhim)
        ON DELETE CASCADE ON UPDATE CASCADE
) COMMENT = 'Bảng DanhGia — đánh giá phim từ khách hàng (1–10 điểm)';

-- ============================================================
-- 15. BẢNG DIEMTICHLUY (Lịch sử tích lũy điểm)
-- ============================================================
CREATE TABLE DiemTichLuy (
    maDiem          INT AUTO_INCREMENT PRIMARY KEY,
    maKhachHang     INT         NOT NULL,
    maBooking       INT         DEFAULT NULL,
    soDiem          INT         NOT NULL COMMENT 'Số điểm thay đổi (+ hoặc -)',
    loaiGiaoDich    ENUM('TichLuy', 'SuDung', 'HoanTra') NOT NULL DEFAULT 'TichLuy',
    moTa            VARCHAR(255) DEFAULT NULL,
    thoiGian        DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_DiemTichLuy_KhachHang
        FOREIGN KEY (maKhachHang) REFERENCES KhachHang(maKhachHang)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_DiemTichLuy_Booking
        FOREIGN KEY (maBooking) REFERENCES Booking(maBooking)
        ON DELETE SET NULL ON UPDATE CASCADE
) COMMENT = 'Bảng DiemTichLuy — lịch sử thay đổi điểm tích lũy khách hàng';

-- ============================================================
-- 16. BẢNG LICHSUHOATDONG (Log hoạt động hệ thống — bonus)
-- ============================================================
CREATE TABLE LichSuHoatDong (
    maLog           INT AUTO_INCREMENT PRIMARY KEY,
    maNguoiDung     INT         DEFAULT NULL,
    hanhDong        VARCHAR(100) NOT NULL,
    bangLienQuan    VARCHAR(50)  DEFAULT NULL,
    maDoiTuong      INT          DEFAULT NULL,
    chiTiet         TEXT         DEFAULT NULL,
    thoiGian        DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_Log_NguoiDung
        FOREIGN KEY (maNguoiDung) REFERENCES NguoiDung(maNguoiDung)
        ON DELETE SET NULL ON UPDATE CASCADE
) COMMENT = 'Bảng log hoạt động hệ thống — ghi lại thao tác của người dùng';

-- ============================================================
-- INDEX phụ trợ
-- ============================================================
CREATE INDEX idx_SuatChieu_PhimPhong ON SuatChieu(maPhim, maPhongChieu);
CREATE INDEX idx_SuatChieu_ThoiGian ON SuatChieu(thoiGianBatDau);
CREATE INDEX idx_Booking_KhachHang ON Booking(maKhachHang);
CREATE INDEX idx_Booking_SuatChieu ON Booking(maSuatChieu);
CREATE INDEX idx_Booking_TrangThai ON Booking(trangThai);
CREATE INDEX idx_ChiTietBooking_Ghe ON ChiTietBooking(maGhe);
CREATE INDEX idx_Ghe_PhongChieu ON Ghe(maPhongChieu);
CREATE INDEX idx_DanhGia_Phim ON DanhGia(maPhim);

-- ============================================================
-- KẾT THÚC schema.sql
-- ============================================================
