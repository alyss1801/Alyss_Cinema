-- ============================================================
-- BTL2 HỆ CƠ SỞ DỮ LIỆU — HỆ THỐNG ĐẶT VÉ RẠP CHIẾU PHIM
-- File: procedures_query.sql
-- Mục đích: 2 stored procedure hiển thị dữ liệu
-- Thứ tự chạy: schema.sql → data.sql → triggers.sql →
--              procedures_crud.sql → procedures_query.sql
-- ============================================================

USE RapChieuPhim;

-- ============================================================
-- STORED PROCEDURE 1: sp_DanhSachBookingTheoKhachHang
-- Mục đích: Hiển thị danh sách booking của khách hàng với đầy đủ
--           thông tin phim, suất chiếu, ghế, trạng thái
-- Tham số đầu vào:
--   p_maKhachHang : mã khách hàng (NULL = tất cả khách hàng)
--   p_trangThai   : lọc theo trạng thái (NULL = tất cả)
--   p_tuNgay      : ngày bắt đầu lọc (NULL = không giới hạn)
--   p_denNgay     : ngày kết thúc lọc (NULL = không giới hạn)
-- Kết quả trả về:
--   JOIN: Booking + ChiTietBooking + SuatChieu + Phim + PhongChieu + KhachHang + NguoiDung
--   ORDER BY: thời gian đặt DESC
-- ============================================================
DELIMITER $$

CREATE PROCEDURE sp_DanhSachBookingTheoKhachHang(
    IN p_maKhachHang INT,
    IN p_trangThai   VARCHAR(20),
    IN p_tuNgay      DATE,
    IN p_denNgay     DATE
)
BEGIN
    SELECT
        b.maBooking,
        nd.hoTen                    AS tenKhachHang,
        nd.soDienThoai,
        p.tenPhim,
        pc.tenPhongChieu,
        pc.loaiPhong,
        sc.thoiGianBatDau,
        sc.thoiGianKetThuc,
        -- Danh sách ghế (gom từ ChiTietBooking)
        GROUP_CONCAT(
            CONCAT(g.hangGhe, g.soGhe, ' (', g.loaiGhe, ')')
            ORDER BY g.hangGhe, g.soGhe
            SEPARATOR ', '
        )                           AS danhSachGhe,
        COUNT(ctb.maChiTiet)        AS soGhe,
        b.tongTien,
        b.trangThai                 AS trangThaiBooking,
        b.thoiGianDat,
        COALESCE(km.maCode, '—')   AS maGiamGia,
        b.ghiChu
    FROM Booking b
    -- JOIN với bảng liên quan
    INNER JOIN KhachHang kh ON b.maKhachHang = kh.maKhachHang
    INNER JOIN NguoiDung nd ON kh.maKhachHang = nd.maNguoiDung
    INNER JOIN SuatChieu sc ON b.maSuatChieu  = sc.maSuatChieu
    INNER JOIN Phim p       ON sc.maPhim      = p.maPhim
    INNER JOIN PhongChieu pc ON sc.maPhongChieu = pc.maPhongChieu
    LEFT  JOIN ChiTietBooking ctb ON b.maBooking = ctb.maBooking
    LEFT  JOIN Ghe g             ON ctb.maGhe    = g.maGhe
    LEFT  JOIN KhuyenMai km      ON b.maKhuyenMai = km.maKhuyenMai
    WHERE
        -- Lọc theo khách hàng (optional)
        (p_maKhachHang IS NULL OR b.maKhachHang = p_maKhachHang)
        -- Lọc theo trạng thái (optional)
        AND (p_trangThai IS NULL OR p_trangThai = '' OR b.trangThai = p_trangThai)
        -- Lọc theo khoảng thời gian đặt (optional)
        AND (p_tuNgay IS NULL OR DATE(b.thoiGianDat) >= p_tuNgay)
        AND (p_denNgay IS NULL OR DATE(b.thoiGianDat) <= p_denNgay)
    GROUP BY
        b.maBooking, nd.hoTen, nd.soDienThoai,
        p.tenPhim, pc.tenPhongChieu, pc.loaiPhong,
        sc.thoiGianBatDau, sc.thoiGianKetThuc,
        b.tongTien, b.trangThai, b.thoiGianDat,
        km.maCode, b.ghiChu
    ORDER BY b.thoiGianDat DESC;
END$$

DELIMITER ;

-- ============================================================
-- STORED PROCEDURE 2: sp_ThongKeDoanhThuPhim
-- Mục đích: Thống kê doanh thu từng phim trong khoảng thời gian
-- Tham số đầu vào:
--   p_tuNgay          : ngày bắt đầu thống kê
--   p_denNgay         : ngày kết thúc thống kê
--   p_nguongDoanhThu  : ngưỡng doanh thu tối thiểu (HAVING)
-- Kết quả trả về:
--   Tên phim, số booking, số vé bán, tổng doanh thu, doanh thu TB/suất
-- Aggregate: SUM, COUNT, AVG
-- ============================================================
DELIMITER $$

CREATE PROCEDURE sp_ThongKeDoanhThuPhim(
    IN p_tuNgay          DATE,
    IN p_denNgay         DATE,
    IN p_nguongDoanhThu  DECIMAL(12,0)
)
BEGIN
    -- Validate input: ngày bắt đầu phải trước ngày kết thúc
    IF p_tuNgay IS NOT NULL AND p_denNgay IS NOT NULL AND p_tuNgay > p_denNgay THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Lỗi: Ngày bắt đầu phải trước hoặc bằng ngày kết thúc.';
    END IF;

    -- Đặt ngưỡng mặc định = 0 nếu NULL
    IF p_nguongDoanhThu IS NULL THEN
        SET p_nguongDoanhThu = 0;
    END IF;

    SELECT
        p.maPhim,
        p.tenPhim,
        p.daoDien,
        p.thoiLuong,
        p.gioiHanDoTuoi,
        p.diemDanhGiaTB,
        -- Số suất chiếu
        COUNT(DISTINCT sc.maSuatChieu)              AS soSuatChieu,
        -- Số booking confirmed
        COUNT(DISTINCT b.maBooking)                  AS soBooking,
        -- Tổng số vé bán được
        COUNT(ctb.maChiTiet)                         AS soVeBan,
        -- Tổng doanh thu (từ thanh toán thành công)
        COALESCE(SUM(tt.soTien), 0)                  AS tongDoanhThu,
        -- Doanh thu trung bình mỗi suất chiếu
        CASE
            WHEN COUNT(DISTINCT sc.maSuatChieu) > 0
            THEN ROUND(COALESCE(SUM(tt.soTien), 0) / COUNT(DISTINCT sc.maSuatChieu))
            ELSE 0
        END                                           AS doanhThuTBSuat,
        -- Doanh thu trung bình mỗi booking
        CASE
            WHEN COUNT(DISTINCT b.maBooking) > 0
            THEN ROUND(AVG(tt.soTien))
            ELSE 0
        END                                           AS doanhThuTBBooking
    FROM Phim p
    LEFT JOIN SuatChieu sc ON p.maPhim = sc.maPhim
    LEFT JOIN Booking b ON sc.maSuatChieu = b.maSuatChieu
                        AND b.trangThai = 'Confirmed'
    LEFT JOIN ChiTietBooking ctb ON b.maBooking = ctb.maBooking
    LEFT JOIN ThanhToan tt ON b.maBooking = tt.maBooking
                           AND tt.trangThai = 'ThanhCong'
    WHERE
        -- Lọc theo khoảng thời gian suất chiếu
        (p_tuNgay IS NULL OR DATE(sc.thoiGianBatDau) >= p_tuNgay)
        AND (p_denNgay IS NULL OR DATE(sc.thoiGianBatDau) <= p_denNgay)
    GROUP BY
        p.maPhim, p.tenPhim, p.daoDien,
        p.thoiLuong, p.gioiHanDoTuoi, p.diemDanhGiaTB
    HAVING
        tongDoanhThu >= p_nguongDoanhThu
    ORDER BY tongDoanhThu DESC;
END$$

DELIMITER ;

-- ============================================================
-- KẾT THÚC procedures_query.sql
-- ============================================================
