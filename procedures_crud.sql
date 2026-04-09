-- ============================================================
-- BTL2 HỆ CƠ SỞ DỮ LIỆU — HỆ THỐNG ĐẶT VÉ RẠP CHIẾU PHIM
-- File: procedures_crud.sql
-- Mục đích: 3 stored procedure CRUD cho bảng Booking (bảng trung tâm)
-- Thứ tự chạy: schema.sql → data.sql → triggers.sql → procedures_crud.sql
-- ============================================================

USE RapChieuPhim;

-- ============================================================
-- STORED PROCEDURE 1: sp_ThemBooking
-- Mục đích: Thêm booking mới cho khách hàng
-- Tham số đầu vào:
--   p_maKhachHang   : mã khách hàng đặt vé
--   p_maSuatChieu   : mã suất chiếu muốn đặt
--   p_danhSachGhe   : JSON array chứa mã ghế (VD: '[1, 2, 3]')
--   p_maCodeGiamGia : mã code giảm giá (nullable, VD: 'WELCOME10')
-- Tham số đầu ra:
--   p_maBookingMoi  : mã booking vừa tạo
-- Logic:
--   1. Validate suất chiếu còn hoạt động và chưa bắt đầu
--   2. Validate số lượng ghế (1-8)
--   3. Validate từng ghế chưa bị đặt
--   4. Validate mã giảm giá (nếu có)
--   5. Validate khách hàng đủ tuổi xem phim
--   6. Tính giá cho từng ghế
--   7. Insert Booking + ChiTietBooking
-- ============================================================
DELIMITER $$

CREATE PROCEDURE sp_ThemBooking(
    IN p_maKhachHang   INT,
    IN p_maSuatChieu   INT,
    IN p_danhSachGhe   JSON,
    IN p_maCodeGiamGia VARCHAR(50),
    OUT p_maBookingMoi INT
)
BEGIN
    -- Biến cục bộ
    DECLARE v_soGhe INT DEFAULT 0;
    DECLARE v_maPhim INT;
    DECLARE v_maPhongChieu INT;
    DECLARE v_thoiGianBatDau DATETIME;
    DECLARE v_trangThaiSC VARCHAR(20);
    DECLARE v_giaVeCoBan DECIMAL(12,0);
    DECLARE v_gioiHanDoTuoi VARCHAR(5);
    DECLARE v_ngaySinhKH DATE;
    DECLARE v_tuoiKH INT;
    DECLARE v_maKhuyenMai INT DEFAULT NULL;
    DECLARE v_loaiGiamGia VARCHAR(20);
    DECLARE v_giaTriGiam DECIMAL(12,2);
    DECLARE v_giaTriToiDa DECIMAL(12,0);
    DECLARE v_soLuotConLai INT;
    DECLARE v_ngayHetHanKM DATE;
    DECLARE v_dieuKienToiThieu DECIMAL(12,0);
    DECLARE v_loaiPhong VARCHAR(10);
    DECLARE v_heSoPhong DECIMAL(3,1);
    DECLARE v_maGheHienTai INT;
    DECLARE v_loaiGheHienTai VARCHAR(10);
    DECLARE v_heSoGhe DECIMAL(3,1);
    DECLARE v_giaVeGhe DECIMAL(12,0);
    DECLARE v_tongGiaGhe DECIMAL(12,0) DEFAULT 0;
    DECLARE v_maPhongChieuGhe INT;
    DECLARE v_trangThaiGhe VARCHAR(20);
    DECLARE v_gheDaDat INT;
    DECLARE v_idx INT DEFAULT 0;
    DECLARE v_khachHangTonTai INT;

    -- Xử lý lỗi: rollback nếu có exception
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Bắt đầu transaction
    START TRANSACTION;

    -- ---- VALIDATE 1: Khách hàng tồn tại ----
    SELECT COUNT(*) INTO v_khachHangTonTai
    FROM KhachHang WHERE maKhachHang = p_maKhachHang;

    IF v_khachHangTonTai = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Lỗi: Khách hàng không tồn tại trong hệ thống.';
    END IF;

    -- ---- VALIDATE 2: Suất chiếu tồn tại và hợp lệ ----
    SELECT maPhim, maPhongChieu, thoiGianBatDau, trangThai, giaVeCoBan
    INTO v_maPhim, v_maPhongChieu, v_thoiGianBatDau, v_trangThaiSC, v_giaVeCoBan
    FROM SuatChieu
    WHERE maSuatChieu = p_maSuatChieu;

    IF v_maPhim IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Lỗi: Suất chiếu không tồn tại.';
    END IF;

    IF v_trangThaiSC != 'MoCua' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Lỗi: Suất chiếu không ở trạng thái mở bán vé (đã chiếu hoặc bị hủy).';
    END IF;

    IF v_thoiGianBatDau <= NOW() THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Lỗi: Suất chiếu đã bắt đầu, không thể đặt vé.';
    END IF;

    -- ---- VALIDATE 3: Số lượng ghế (RC4: 1-8 ghế) ----
    SET v_soGhe = JSON_LENGTH(p_danhSachGhe);

    IF v_soGhe = 0 OR v_soGhe IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Lỗi: Vui lòng chọn ít nhất 1 ghế.';
    END IF;

    IF v_soGhe > 8 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Lỗi: Số ghế đặt trong 1 booking không được vượt quá 8 ghế.';
    END IF;

    -- ---- VALIDATE 4: Khách hàng đủ tuổi (RC3) ----
    SELECT gioiHanDoTuoi INTO v_gioiHanDoTuoi
    FROM Phim WHERE maPhim = v_maPhim;

    SELECT ngaySinh INTO v_ngaySinhKH
    FROM KhachHang WHERE maKhachHang = p_maKhachHang;

    SET v_tuoiKH = TIMESTAMPDIFF(YEAR, v_ngaySinhKH, CURDATE());

    IF v_gioiHanDoTuoi = 'C13' AND v_tuoiKH < 13 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Lỗi: Khách hàng chưa đủ 13 tuổi để xem phim này (phim C13).';
    END IF;

    IF v_gioiHanDoTuoi = 'C16' AND v_tuoiKH < 16 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Lỗi: Khách hàng chưa đủ 16 tuổi để xem phim này (phim C16).';
    END IF;

    IF v_gioiHanDoTuoi = 'C18' AND v_tuoiKH < 18 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Lỗi: Khách hàng chưa đủ 18 tuổi để xem phim này (phim C18).';
    END IF;

    -- ---- VALIDATE 5: Mã giảm giá (RC6, RC7) ----
    IF p_maCodeGiamGia IS NOT NULL AND p_maCodeGiamGia != '' THEN
        SELECT maKhuyenMai, loaiGiamGia, giaTriGiam, giaTriToiDa,
               ngayHetHan, (soLuotToiDa - soLuotDaDung), dieuKienToiThieu
        INTO v_maKhuyenMai, v_loaiGiamGia, v_giaTriGiam, v_giaTriToiDa,
             v_ngayHetHanKM, v_soLuotConLai, v_dieuKienToiThieu
        FROM KhuyenMai
        WHERE maCode = p_maCodeGiamGia AND trangThai = 'HoatDong';

        IF v_maKhuyenMai IS NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Lỗi: Mã giảm giá không tồn tại hoặc đã ngừng sử dụng.';
        END IF;

        -- RC6: Không áp dụng sau ngày hết hạn
        IF CURDATE() > v_ngayHetHanKM THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Lỗi: Mã giảm giá đã hết hạn sử dụng.';
        END IF;

        -- RC7: Còn lượt sử dụng
        IF v_soLuotConLai <= 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Lỗi: Mã giảm giá đã hết lượt sử dụng.';
        END IF;
    END IF;

    -- ---- Lấy hệ số loại phòng chiếu ----
    SELECT loaiPhong INTO v_loaiPhong
    FROM PhongChieu WHERE maPhongChieu = v_maPhongChieu;

    SET v_heSoPhong = CASE v_loaiPhong
        WHEN '2D'   THEN 1.0
        WHEN '3D'   THEN 1.3
        WHEN 'IMAX' THEN 1.8
        ELSE 1.0
    END;

    -- ---- INSERT BOOKING (tạm tongTien = 0, trigger sẽ cập nhật) ----
    INSERT INTO Booking (maKhachHang, maSuatChieu, maKhuyenMai, thoiGianDat, tongTien, trangThai)
    VALUES (p_maKhachHang, p_maSuatChieu, v_maKhuyenMai, NOW(), 0, 'Pending');

    SET p_maBookingMoi = LAST_INSERT_ID();

    -- ---- VALIDATE + INSERT từng ghế ----
    SET v_idx = 0;
    WHILE v_idx < v_soGhe DO
        SET v_maGheHienTai = JSON_EXTRACT(p_danhSachGhe, CONCAT('$[', v_idx, ']'));

        -- Kiểm tra ghế tồn tại và thuộc phòng chiếu tương ứng
        SELECT maPhongChieu, loaiGhe, trangThai
        INTO v_maPhongChieuGhe, v_loaiGheHienTai, v_trangThaiGhe
        FROM Ghe WHERE maGhe = v_maGheHienTai;

        IF v_maPhongChieuGhe IS NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Lỗi: Một hoặc nhiều ghế không tồn tại trong hệ thống.';
        END IF;

        IF v_maPhongChieuGhe != v_maPhongChieu THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Lỗi: Ghế không thuộc phòng chiếu của suất chiếu này.';
        END IF;

        IF v_trangThaiGhe != 'HoatDong' THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Lỗi: Ghế đang hỏng hoặc bảo trì, không thể đặt.';
        END IF;

        -- Tính giá vé cho ghế này
        SET v_heSoGhe = CASE v_loaiGheHienTai
            WHEN 'Thuong' THEN 1.0
            WHEN 'VIP'    THEN 1.5
            WHEN 'Doi'    THEN 2.0
            ELSE 1.0
        END;

        SET v_giaVeGhe = ROUND(v_giaVeCoBan * v_heSoGhe * v_heSoPhong);

        -- Insert chi tiết booking (trigger trg_KiemTraGheDaDat sẽ check ghế trùng)
        INSERT INTO ChiTietBooking (maBooking, maGhe, giaVe)
        VALUES (p_maBookingMoi, v_maGheHienTai, v_giaVeGhe);

        SET v_tongGiaGhe = v_tongGiaGhe + v_giaVeGhe;
        SET v_idx = v_idx + 1;
    END WHILE;

    -- ---- Kiểm tra điều kiện tối thiểu cho mã giảm giá ----
    IF v_maKhuyenMai IS NOT NULL AND v_tongGiaGhe < v_dieuKienToiThieu THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Lỗi: Tổng giá trị đơn hàng chưa đạt điều kiện tối thiểu để áp dụng mã giảm giá.';
    END IF;

    -- ---- Cập nhật lượt sử dụng mã khuyến mãi ----
    IF v_maKhuyenMai IS NOT NULL THEN
        UPDATE KhuyenMai
        SET soLuotDaDung = soLuotDaDung + 1
        WHERE maKhuyenMai = v_maKhuyenMai;
    END IF;

    COMMIT;
END$$

DELIMITER ;

-- ============================================================
-- STORED PROCEDURE 2: sp_SuaBooking
-- Mục đích: Cập nhật trạng thái của booking
-- Tham số đầu vào:
--   p_maBooking      : mã booking cần sửa
--   p_trangThaiMoi   : trạng thái mới ('Pending', 'Confirmed')
-- Logic:
--   1. Kiểm tra booking tồn tại
--   2. Không cho sửa booking đã Cancelled
--   3. Không cho sửa nếu suất chiếu đã bắt đầu (RC8)
--   4. Validate trạng thái đầu vào hợp lệ
--   5. Cập nhật trạng thái
-- ============================================================
DELIMITER $$

CREATE PROCEDURE sp_SuaBooking(
    IN p_maBooking    INT,
    IN p_trangThaiMoi VARCHAR(20)
)
BEGIN
    DECLARE v_trangThaiHienTai VARCHAR(20);
    DECLARE v_maSuatChieu INT;
    DECLARE v_thoiGianBatDau DATETIME;
    DECLARE v_bookingTonTai INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- ---- VALIDATE 1: Booking tồn tại ----
    SELECT COUNT(*) INTO v_bookingTonTai
    FROM Booking WHERE maBooking = p_maBooking;

    IF v_bookingTonTai = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Lỗi: Booking không tồn tại trong hệ thống.';
    END IF;

    -- ---- VALIDATE 2: Trạng thái đầu vào hợp lệ ----
    IF p_trangThaiMoi NOT IN ('Pending', 'Confirmed') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Lỗi: Trạng thái mới phải là "Pending" hoặc "Confirmed". Để hủy, vui lòng sử dụng chức năng xóa booking.';
    END IF;

    -- ---- Lấy thông tin booking hiện tại ----
    SELECT trangThai, maSuatChieu
    INTO v_trangThaiHienTai, v_maSuatChieu
    FROM Booking WHERE maBooking = p_maBooking;

    -- ---- VALIDATE 3: Không sửa booking đã cancelled ----
    IF v_trangThaiHienTai = 'Cancelled' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Lỗi: Không thể sửa booking đã bị hủy. Vui lòng tạo booking mới.';
    END IF;

    -- ---- VALIDATE 4: Không sửa nếu suất chiếu đã bắt đầu (RC8) ----
    SELECT thoiGianBatDau INTO v_thoiGianBatDau
    FROM SuatChieu WHERE maSuatChieu = v_maSuatChieu;

    IF v_thoiGianBatDau <= NOW() THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Lỗi: Không thể sửa booking vì suất chiếu đã bắt đầu.';
    END IF;

    -- ---- VALIDATE 5: Không sửa nếu trạng thái không đổi ----
    IF v_trangThaiHienTai = p_trangThaiMoi THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Lỗi: Booking đã ở trạng thái này rồi.';
    END IF;

    -- ---- Cập nhật trạng thái ----
    UPDATE Booking
    SET trangThai = p_trangThaiMoi
    WHERE maBooking = p_maBooking;

    COMMIT;
END$$

DELIMITER ;

-- ============================================================
-- STORED PROCEDURE 3: sp_XoaBooking
-- Mục đích: Xóa (hủy) booking
-- Tham số đầu vào:
--   p_maBooking : mã booking cần xóa
-- Logic:
--   1. Kiểm tra booking tồn tại
--   2. Chỉ xóa booking Pending (chưa thanh toán)
--   3. Booking Confirmed → thông báo cần quy trình hoàn tiền
--   4. Không xóa nếu suất chiếu đã bắt đầu (RC8)
--   5. Xóa ChiTietBooking trước, rồi đánh dấu Cancelled
-- ============================================================
DELIMITER $$

CREATE PROCEDURE sp_XoaBooking(
    IN p_maBooking INT
)
BEGIN
    DECLARE v_trangThai VARCHAR(20);
    DECLARE v_maSuatChieu INT;
    DECLARE v_thoiGianBatDau DATETIME;
    DECLARE v_bookingTonTai INT;
    DECLARE v_maKhuyenMai INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- ---- VALIDATE 1: Booking tồn tại ----
    SELECT COUNT(*) INTO v_bookingTonTai
    FROM Booking WHERE maBooking = p_maBooking;

    IF v_bookingTonTai = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Lỗi: Booking không tồn tại trong hệ thống.';
    END IF;

    -- ---- Lấy thông tin booking ----
    SELECT trangThai, maSuatChieu, maKhuyenMai
    INTO v_trangThai, v_maSuatChieu, v_maKhuyenMai
    FROM Booking WHERE maBooking = p_maBooking;

    -- ---- VALIDATE 2: Trạng thái cho phép xóa ----
    IF v_trangThai = 'Cancelled' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Lỗi: Booking này đã được hủy trước đó.';
    END IF;

    IF v_trangThai = 'Confirmed' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Lỗi: Không thể xóa booking đã xác nhận (Confirmed). Vui lòng liên hệ quầy hỗ trợ để thực hiện quy trình hoàn tiền.';
    END IF;

    -- ---- VALIDATE 3: Suất chiếu chưa bắt đầu (RC8) ----
    SELECT thoiGianBatDau INTO v_thoiGianBatDau
    FROM SuatChieu WHERE maSuatChieu = v_maSuatChieu;

    IF v_thoiGianBatDau <= NOW() THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Lỗi: Không thể hủy booking vì suất chiếu đã bắt đầu.';
    END IF;

    -- ---- Xóa chi tiết booking trước ----
    DELETE FROM ChiTietBooking WHERE maBooking = p_maBooking;

    -- ---- Đánh dấu Cancelled (không xóa hẳn để giữ lịch sử) ----
    UPDATE Booking
    SET trangThai = 'Cancelled', tongTien = 0
    WHERE maBooking = p_maBooking;

    -- ---- Hoàn lại lượt sử dụng mã khuyến mãi (nếu có) ----
    IF v_maKhuyenMai IS NOT NULL THEN
        UPDATE KhuyenMai
        SET soLuotDaDung = GREATEST(soLuotDaDung - 1, 0)
        WHERE maKhuyenMai = v_maKhuyenMai;
    END IF;

    COMMIT;
END$$

DELIMITER ;

-- ============================================================
-- KẾT THÚC procedures_crud.sql
-- ============================================================
