# ============================================================
# BTL2 — HỆ THỐNG ĐẶT VÉ RẠP CHIẾU PHIM
# File: config.py
# Mục đích: Cấu hình kết nối MySQL và các thông số ứng dụng
# ============================================================
import os
import re


def _clean_env(value, mode='text'):
    """Normalize env values that may contain accidental quotes/newlines/spaces."""
    if value is None:
        return None

    v = str(value).strip()
    # Remove wrapping quotes repeatedly and trim spaces again.
    for _ in range(3):
        v = v.strip().strip('"').strip("'").strip()
    # Remove common escaping artifacts.
    v = v.replace('\\', '').strip()

    if mode == 'port':
        m = re.search(r'\d+', v)
        return int(m.group(0)) if m else 3306

    return v

class Config:
    """Cấu hình chính của ứng dụng Flask."""

    # Flask Secret Key (dùng cho session, flash message)
    SECRET_KEY = _clean_env(os.environ.get('SECRET_KEY', 'btl2-rap-chieu-phim-secret-key-2026'))

    # Cấu hình MySQL
    MYSQL_HOST = _clean_env(os.environ.get('MYSQL_HOST', 'localhost'))
    MYSQL_PORT = _clean_env(os.environ.get('MYSQL_PORT', 3306), mode='port')
    MYSQL_USER = _clean_env(os.environ.get('MYSQL_USER', 'root'))
    MYSQL_PASSWORD = _clean_env(os.environ.get('MYSQL_PASSWORD', ''))
    MYSQL_DATABASE = _clean_env(os.environ.get('MYSQL_DATABASE', 'railway'))

    # Connection Pool
    MYSQL_POOL_NAME = 'cinema_pool'
    MYSQL_POOL_SIZE = 5

    # Phân trang
    ITEMS_PER_PAGE = 10
