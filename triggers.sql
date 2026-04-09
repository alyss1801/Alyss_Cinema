-- ============================================================
-- BTL2 HỆ CƠ SỞ DỮ LIỆU — HỆ THỐNG ĐẶT VÉ RẠP CHIẾU PHIM
-- File: triggers.sql
-- Mục đích: Tạo tất cả triggers cho hệ thống
-- Thứ tự chạy: schema.sql → data.sql → triggers.sql
-- ============================================================

USE RapChieuPhim;

-- ============================================================
-- TRIGGER 1: trg_KiemTraGheDaDat
-- Loại: BEFORE INSERT trên bảng ChiTietBooking
-- Mục đích: Kiểm tra 1 ghế không được đặt 2 lần trong cùng 1 suất chiếu
--           (ràng buộc RC2)
-- Logic:
--   - Lấy maSuatChieu từ Booking tương ứng
--   - Kiểm tra ghế đó đã tồn tại trong ChiTietBooking nào khác
--     của cùng suất chiếu có trạng thái Pending hoặc Confirmed
--   - Nếu có → SIGNAL lỗi
-- ============================================================
DELIMITER $$

CREATE TRIGGER trg_KiemTraGheDaDat
BEFORE INSERT ON ChiTietBooking
FOR EACH ROW
BEGIN
    DECLARE v_maSuatChieu INT;
    DECLARE v_soGheDaDat INT;
    DECLARE v_tenGhe VARCHAR(10);
    DECLARE v_errMsg VARCHAR(255);

    -- Lấy mã suất chiếu của booking hiện tại
    SELECT maSuatChieu INTO v_maSuatChieu
    FROM Booking
    WHERE maBooking = NEW.maBooking;

    -- Kiểm tra ghế đã được đặt trong cùng suất chiếu chưa
    SELECT COUNT(*) INTO v_soGheDaDat
    FROM ChiTietBooking ctb
    INNER JOIN Booking b ON ctb.maBooking = b.maBooking
    WHERE ctb.maGhe = NEW.maGhe
      AND b.maSuatChieu = v_maSuatChieu
      AND b.trangThai IN ('Pending', 'Confirmed')
      AND b.maBooking != NEW.maBooking;

    IF v_soGheDaDat > 0 THEN
        -- Lấy thông tin ghế để thông báo lỗi rõ ràng
        SELECT CONCAT(hangGhe, soGhe) INTO v_tenGhe
        FROM Ghe WHERE maGhe = NEW.maGhe;

        SET v_errMsg = CONCAT('Ghe ', v_tenGhe, ' (ma ', NEW.maGhe,
                ') da duoc dat trong suat chieu nay. Vui long chon ghe khac.');
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = v_errMsg;
    END IF;
END$$

DELIMITER ;

-- ============================================================
-- TRIGGER 2: trg_CapNhatTongTienBooking_Insert
-- Loại: AFTER INSERT trên bảng ChiTietBooking
-- Mục đích: Cập nhật thuộc tính DẪN XUẤT tongTien trong Booking
-- Logic:
--   - Tính tổng giá vé từ tất cả ChiTietBooking của booking
--   - Áp dụng giảm giá từ KhuyenMai nếu có
--   - Cập nhật cột tongTien
-- ============================================================
DELIMITER $$

CREATE TRIGGER trg_CapNhatTongTienBooking_Insert
AFTER INSERT ON ChiTietBooking
FOR EACH ROW
BEGIN
    DECLARE v_tongGiaGhe DECIMAL(12,0);
    DECLARE v_maKhuyenMai INT;
    DECLARE v_loaiGiamGia VARCHAR(20);
    DECLARE v_giaTriGiam DECIMAL(12,2);
    DECLARE v_giaTriToiDa DECIMAL(12,0);
    DECLARE v_tongTienSauGiam DECIMAL(12,0);
    DECLARE v_soTienGiam DECIMAL(12,0);

    -- Tính tổng giá ghế trong booking
    SELECT COALESCE(SUM(giaVe), 0) INTO v_tongGiaGhe
    FROM ChiTietBooking
    WHERE maBooking = NEW.maBooking;

    -- Lấy mã khuyến mãi của booking
    SELECT maKhuyenMai INTO v_maKhuyenMai
    FROM Booking
    WHERE maBooking = NEW.maBooking;

    SET v_tongTienSauGiam = v_tongGiaGhe;

    -- Áp dụng khuyến mãi nếu có
    IF v_maKhuyenMai IS NOT NULL THEN
        SELECT loaiGiamGia, giaTriGiam, giaTriToiDa
        INTO v_loaiGiamGia, v_giaTriGiam, v_giaTriToiDa
        FROM KhuyenMai
        WHERE maKhuyenMai = v_maKhuyenMai;

        IF v_loaiGiamGia = 'PhanTram' THEN
            SET v_soTienGiam = v_tongGiaGhe * v_giaTriGiam / 100;
            -- Áp dụng giới hạn giảm tối đa
            IF v_giaTriToiDa IS NOT NULL AND v_soTienGiam > v_giaTriToiDa THEN
                SET v_soTienGiam = v_giaTriToiDa;
            END IF;
        ELSE
            -- Giảm cố định
            SET v_soTienGiam = v_giaTriGiam;
        END IF;

        SET v_tongTienSauGiam = GREATEST(v_tongGiaGhe - v_soTienGiam, 0);
    END IF;

    -- Cập nhật tổng tiền
    UPDATE Booking
    SET tongTien = v_tongTienSauGiam
    WHERE maBooking = NEW.maBooking;
END$$

DELIMITER ;

-- ============================================================
-- TRIGGER 3: trg_CapNhatTongTienBooking_Delete
-- Loại: AFTER DELETE trên bảng ChiTietBooking
-- Mục đích: Cập nhật lại tongTien khi xóa chi tiết ghế
-- ============================================================
DELIMITER $$

CREATE TRIGGER trg_CapNhatTongTienBooking_Delete
AFTER DELETE ON ChiTietBooking
FOR EACH ROW
BEGIN
    DECLARE v_tongGiaGhe DECIMAL(12,0);
    DECLARE v_maKhuyenMai INT;
    DECLARE v_loaiGiamGia VARCHAR(20);
    DECLARE v_giaTriGiam DECIMAL(12,2);
    DECLARE v_giaTriToiDa DECIMAL(12,0);
    DECLARE v_tongTienSauGiam DECIMAL(12,0);
    DECLARE v_soTienGiam DECIMAL(12,0);

    SELECT COALESCE(SUM(giaVe), 0) INTO v_tongGiaGhe
    FROM ChiTietBooking
    WHERE maBooking = OLD.maBooking;

    SELECT maKhuyenMai INTO v_maKhuyenMai
    FROM Booking
    WHERE maBooking = OLD.maBooking;

    SET v_tongTienSauGiam = v_tongGiaGhe;

    IF v_maKhuyenMai IS NOT NULL THEN
        SELECT loaiGiamGia, giaTriGiam, giaTriToiDa
        INTO v_loaiGiamGia, v_giaTriGiam, v_giaTriToiDa
        FROM KhuyenMai
        WHERE maKhuyenMai = v_maKhuyenMai;

        IF v_loaiGiamGia = 'PhanTram' THEN
            SET v_soTienGiam = v_tongGiaGhe * v_giaTriGiam / 100;
            IF v_giaTriToiDa IS NOT NULL AND v_soTienGiam > v_giaTriToiDa THEN
                SET v_soTienGiam = v_giaTriToiDa;
            END IF;
        ELSE
            SET v_soTienGiam = v_giaTriGiam;
        END IF;

        SET v_tongTienSauGiam = GREATEST(v_tongGiaGhe - v_soTienGiam, 0);
    END IF;

    UPDATE Booking
    SET tongTien = v_tongTienSauGiam
    WHERE maBooking = OLD.maBooking;
END$$

DELIMITER ;

-- ============================================================
-- TRIGGER 4 (Bonus): trg_CapNhatDiemDanhGiaTB_Insert
-- Loại: AFTER INSERT trên bảng DanhGia
-- Mục đích: Cập nhật thuộc tính DẪN XUẤT diemDanhGiaTB trong Phim
-- ============================================================
DELIMITER $$

CREATE TRIGGER trg_CapNhatDiemDanhGiaTB_Insert
AFTER INSERT ON DanhGia
FOR EACH ROW
BEGIN
    DECLARE v_diemTB DECIMAL(3,1);

    SELECT ROUND(AVG(diemDanhGia), 1) INTO v_diemTB
    FROM DanhGia
    WHERE maPhim = NEW.maPhim;

    UPDATE Phim
    SET diemDanhGiaTB = COALESCE(v_diemTB, 0)
    WHERE maPhim = NEW.maPhim;
END$$

DELIMITER ;

-- ============================================================
-- TRIGGER 5 (Bonus): trg_CapNhatDiemDanhGiaTB_Update
-- Loại: AFTER UPDATE trên bảng DanhGia
-- ============================================================
DELIMITER $$

CREATE TRIGGER trg_CapNhatDiemDanhGiaTB_Update
AFTER UPDATE ON DanhGia
FOR EACH ROW
BEGIN
    DECLARE v_diemTB DECIMAL(3,1);

    -- Cập nhật cho phim cũ (nếu thay đổi phim)
    IF OLD.maPhim != NEW.maPhim THEN
        SELECT ROUND(AVG(diemDanhGia), 1) INTO v_diemTB
        FROM DanhGia WHERE maPhim = OLD.maPhim;
        UPDATE Phim SET diemDanhGiaTB = COALESCE(v_diemTB, 0)
        WHERE maPhim = OLD.maPhim;
    END IF;

    -- Cập nhật cho phim mới/hiện tại
    SELECT ROUND(AVG(diemDanhGia), 1) INTO v_diemTB
    FROM DanhGia WHERE maPhim = NEW.maPhim;
    UPDATE Phim SET diemDanhGiaTB = COALESCE(v_diemTB, 0)
    WHERE maPhim = NEW.maPhim;
END$$

DELIMITER ;

-- ============================================================
-- TRIGGER 6 (Bonus): trg_CapNhatDiemDanhGiaTB_Delete
-- Loại: AFTER DELETE trên bảng DanhGia
-- ============================================================
DELIMITER $$

CREATE TRIGGER trg_CapNhatDiemDanhGiaTB_Delete
AFTER DELETE ON DanhGia
FOR EACH ROW
BEGIN
    DECLARE v_diemTB DECIMAL(3,1);

    SELECT ROUND(AVG(diemDanhGia), 1) INTO v_diemTB
    FROM DanhGia WHERE maPhim = OLD.maPhim;

    UPDATE Phim SET diemDanhGiaTB = COALESCE(v_diemTB, 0)
    WHERE maPhim = OLD.maPhim;
END$$

DELIMITER ;

-- ============================================================
-- TRIGGER 7: trg_CapNhatSucChuaPhongChieu_Insert
-- Loại: AFTER INSERT trên bảng Ghe
-- Mục đích: Cập nhật thuộc tính DẪN XUẤT sucChua trong PhongChieu
-- ============================================================
DELIMITER $$

CREATE TRIGGER trg_CapNhatSucChuaPhongChieu_Insert
AFTER INSERT ON Ghe
FOR EACH ROW
BEGIN
    UPDATE PhongChieu
    SET sucChua = (SELECT COUNT(*) FROM Ghe WHERE maPhongChieu = NEW.maPhongChieu AND trangThai = 'HoatDong')
    WHERE maPhongChieu = NEW.maPhongChieu;
END$$

DELIMITER ;

-- ============================================================
-- TRIGGER 8: trg_CapNhatSucChuaPhongChieu_Delete
-- Loại: AFTER DELETE trên bảng Ghe
-- ============================================================
DELIMITER $$

CREATE TRIGGER trg_CapNhatSucChuaPhongChieu_Delete
AFTER DELETE ON Ghe
FOR EACH ROW
BEGIN
    UPDATE PhongChieu
    SET sucChua = (SELECT COUNT(*) FROM Ghe WHERE maPhongChieu = OLD.maPhongChieu AND trangThai = 'HoatDong')
    WHERE maPhongChieu = OLD.maPhongChieu;
END$$

DELIMITER ;

-- ============================================================
-- KẾT THÚC triggers.sql
-- ============================================================
