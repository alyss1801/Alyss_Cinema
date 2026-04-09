-- ============================================================
-- BTL2 HỆ CƠ SỞ DỮ LIỆU — HỆ THỐNG ĐẶT VÉ RẠP CHIẾU PHIM
-- File: functions.sql
-- Mục đích: 2 hàm (function) cho hệ thống
-- Thứ tự chạy: schema.sql → data.sql → triggers.sql →
--              procedures_crud.sql → procedures_query.sql → functions.sql
-- ============================================================

USE RapChieuPhim;

-- ============================================================
-- FUNCTION 1: fn_TinhDiemTichLuy
-- Mục đích: Tính điểm tích lũy của khách hàng dựa trên lịch sử giao dịch
-- Tham số đầu vào:
--   p_maKhachHang : mã khách hàng
-- Giá trị trả về: INT — tổng điểm tích lũy
-- Logic:
--   - Dùng cursor duyệt qua tất cả booking đã Confirmed
--   - Mỗi 50,000 VND chi tiêu = 1 điểm tích lũy
--   - Kiểm tra tham số đầu vào hợp lệ
--   - Cập nhật cột diemTichLuy trong KhachHang
-- ============================================================
DELIMITER $$

CREATE FUNCTION fn_TinhDiemTichLuy(p_maKhachHang INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE v_tongDiem INT DEFAULT 0;
    DECLARE v_tongTienBooking DECIMAL(12,0);
    DECLARE v_diemBooking INT;
    DECLARE v_khachHangTonTai INT;
    DECLARE v_done INT DEFAULT FALSE;

    -- Cursor duyệt qua tất cả booking đã Confirmed của khách hàng
    DECLARE cur_booking CURSOR FOR
        SELECT tongTien
        FROM Booking
        WHERE maKhachHang = p_maKhachHang
          AND trangThai = 'Confirmed'
          AND tongTien > 0;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    -- ---- Kiểm tra khách hàng tồn tại ----
    SELECT COUNT(*) INTO v_khachHangTonTai
    FROM KhachHang WHERE maKhachHang = p_maKhachHang;

    IF v_khachHangTonTai = 0 THEN
        -- Hàm không hỗ trợ SIGNAL, trả về -1 để báo lỗi
        RETURN -1;
    END IF;

    -- ---- Mở cursor và tính điểm ----
    OPEN cur_booking;

    read_loop: LOOP
        FETCH cur_booking INTO v_tongTienBooking;

        IF v_done THEN
            LEAVE read_loop;
        END IF;

        -- Mỗi 50,000 VND = 1 điểm
        SET v_diemBooking = FLOOR(v_tongTienBooking / 50000);

        -- Dùng IF để xử lý: booking có tiền < 50K thì không được điểm
        IF v_diemBooking > 0 THEN
            SET v_tongDiem = v_tongDiem + v_diemBooking;
        END IF;
    END LOOP;

    CLOSE cur_booking;

    -- ---- Cập nhật cột diemTichLuy trong KhachHang ----
    UPDATE KhachHang
    SET diemTichLuy = v_tongDiem
    WHERE maKhachHang = p_maKhachHang;

    RETURN v_tongDiem;
END$$

DELIMITER ;

-- ============================================================
-- FUNCTION 2: fn_GiaSuatChieuTheoGhe
-- Mục đích: Tính giá vé thực tế của một ghế trong một suất chiếu
-- Tham số đầu vào:
--   p_maGhe       : mã ghế
--   p_maSuatChieu : mã suất chiếu
-- Giá trị trả về: DECIMAL(12,0) — giá vé thực tế (VND)
-- Logic:
--   - Giá vé = giá cơ bản suất chiếu × hệ số loại ghế × hệ số loại phòng
--   - Hệ số ghế: Thường=1.0, VIP=1.5, Đôi=2.0
--   - Hệ số phòng: 2D=1.0, 3D=1.3, IMAX=1.8
--   - Kiểm tra ghế phải thuộc phòng chiếu đang chiếu suất đó
--   - Dùng cursor và LOOP để xử lý
-- ============================================================
DELIMITER $$

CREATE FUNCTION fn_GiaSuatChieuTheoGhe(p_maGhe INT, p_maSuatChieu INT)
RETURNS DECIMAL(12,0)
DETERMINISTIC
BEGIN
    DECLARE v_giaVeCoBan DECIMAL(12,0);
    DECLARE v_maPhongChieuSC INT;
    DECLARE v_maPhongChieuGhe INT;
    DECLARE v_loaiGhe VARCHAR(10);
    DECLARE v_loaiPhong VARCHAR(10);
    DECLARE v_heSoGhe DECIMAL(3,1) DEFAULT 1.0;
    DECLARE v_heSoPhong DECIMAL(3,1) DEFAULT 1.0;
    DECLARE v_giaVe DECIMAL(12,0);
    DECLARE v_soLanTinhLuyTien INT DEFAULT 0;
    DECLARE v_giaLuyTien DECIMAL(12,0) DEFAULT 0;
    DECLARE v_buocGia DECIMAL(12,0);
    DECLARE v_gheTonTai INT;
    DECLARE v_suatChieuTonTai INT;

    -- ---- Kiểm tra suất chiếu tồn tại ----
    SELECT COUNT(*) INTO v_suatChieuTonTai
    FROM SuatChieu WHERE maSuatChieu = p_maSuatChieu;

    IF v_suatChieuTonTai = 0 THEN
        RETURN -1; -- Suất chiếu không tồn tại
    END IF;

    -- ---- Kiểm tra ghế tồn tại ----
    SELECT COUNT(*) INTO v_gheTonTai
    FROM Ghe WHERE maGhe = p_maGhe;

    IF v_gheTonTai = 0 THEN
        RETURN -2; -- Ghế không tồn tại
    END IF;

    -- ---- Lấy thông tin suất chiếu ----
    SELECT giaVeCoBan, maPhongChieu
    INTO v_giaVeCoBan, v_maPhongChieuSC
    FROM SuatChieu
    WHERE maSuatChieu = p_maSuatChieu;

    -- ---- Lấy thông tin ghế ----
    SELECT maPhongChieu, loaiGhe
    INTO v_maPhongChieuGhe, v_loaiGhe
    FROM Ghe
    WHERE maGhe = p_maGhe;

    -- ---- Kiểm tra ghế thuộc phòng chiếu của suất chiếu ----
    IF v_maPhongChieuGhe != v_maPhongChieuSC THEN
        RETURN -3; -- Ghế không thuộc phòng chiếu của suất chiếu này
    END IF;

    -- ---- Lấy loại phòng chiếu ----
    SELECT loaiPhong INTO v_loaiPhong
    FROM PhongChieu
    WHERE maPhongChieu = v_maPhongChieuSC;

    -- ---- Tính hệ số loại ghế (dùng IF) ----
    IF v_loaiGhe = 'Thuong' THEN
        SET v_heSoGhe = 1.0;
    ELSEIF v_loaiGhe = 'VIP' THEN
        SET v_heSoGhe = 1.5;
    ELSEIF v_loaiGhe = 'Doi' THEN
        SET v_heSoGhe = 2.0;
    ELSE
        SET v_heSoGhe = 1.0;
    END IF;

    -- ---- Tính hệ số loại phòng (dùng IF) ----
    IF v_loaiPhong = '2D' THEN
        SET v_heSoPhong = 1.0;
    ELSEIF v_loaiPhong = '3D' THEN
        SET v_heSoPhong = 1.3;
    ELSEIF v_loaiPhong = 'IMAX' THEN
        SET v_heSoPhong = 1.8;
    ELSE
        SET v_heSoPhong = 1.0;
    END IF;

    -- ---- Tính giá vé bằng LOOP lũy tiến ----
    -- Logic: Tính giá bằng cách cộng từng bước (giá cơ bản đã nhân hệ số)
    -- Bước 1: Giá cơ bản × hệ số ghế
    -- Bước 2: Kết quả × hệ số phòng
    -- Sử dụng loop để minh họa xử lý lũy tiến (có thể mở rộng thêm phí phụ thu)

    SET v_buocGia = v_giaVeCoBan;
    SET v_soLanTinhLuyTien = 0;

    calc_loop: LOOP
        SET v_soLanTinhLuyTien = v_soLanTinhLuyTien + 1;

        IF v_soLanTinhLuyTien = 1 THEN
            -- Bước 1: Nhân hệ số loại ghế
            SET v_buocGia = ROUND(v_buocGia * v_heSoGhe);
        ELSEIF v_soLanTinhLuyTien = 2 THEN
            -- Bước 2: Nhân hệ số loại phòng
            SET v_buocGia = ROUND(v_buocGia * v_heSoPhong);
        ELSE
            -- Kết thúc loop
            LEAVE calc_loop;
        END IF;
    END LOOP calc_loop;

    SET v_giaVe = v_buocGia;

    RETURN v_giaVe;
END$$

DELIMITER ;

-- ============================================================
-- KẾT THÚC functions.sql
-- ============================================================
