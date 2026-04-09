# ============================================================
# BTL2 — HỆ THỐNG ĐẶT VÉ RẠP CHIẾU PHIM
# File: db.py
# Mục đích: Helper kết nối MySQL qua connection pool
# ============================================================

import mysql.connector
from mysql.connector import pooling, Error
try:
    from .config import Config
except ImportError:
    from config import Config

# Tạo connection pool TOÀN CỤC (tránh tạo mới mỗi request)
_pool = None


def init_pool():
    """Khởi tạo connection pool. Gọi 1 lần khi app start."""
    global _pool
    try:
        _pool = pooling.MySQLConnectionPool(
            pool_name=Config.MYSQL_POOL_NAME,
            pool_size=Config.MYSQL_POOL_SIZE,
            pool_reset_session=True,
            host=Config.MYSQL_HOST,
            port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER,
            password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE,
            charset='utf8mb4',
            collation='utf8mb4_unicode_ci',
            autocommit=False
        )
        print(f"[DB] Connection pool '{Config.MYSQL_POOL_NAME}' đã khởi tạo thành công ({Config.MYSQL_POOL_SIZE} connections).")
    except Error as e:
        print(f"[DB] Lỗi khởi tạo connection pool: {e}")
        raise


def get_connection():
    """Lấy connection từ pool."""
    global _pool
    if _pool is None:
        init_pool()
    return _pool.get_connection()


def execute_query(query, params=None, fetchone=False, fetchall=True, commit=False):
    """
    Thực thi câu SQL thông thường.
    
    Args:
        query: câu SQL
        params: tuple tham số
        fetchone: True nếu chỉ lấy 1 dòng
        fetchall: True nếu lấy tất cả
        commit: True nếu cần commit (INSERT, UPDATE, DELETE)
    Returns:
        dict hoặc list[dict] tùy thuộc fetchone/fetchall
    """
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute(query, params)

        result = None
        if fetchone:
            result = cursor.fetchone()
        elif fetchall:
            result = cursor.fetchall()

        if commit:
            conn.commit()

        return result
    except Error as e:
        if conn and commit:
            conn.rollback()
        raise e
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()


def import_sql_file(filename):
    """Import SQL file vào database."""
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor()
        
        with open(filename, 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        # Split by ; và execute từng statement
        statements = sql_content.split(';')
        count = 0
        for stmt in statements:
            stmt = stmt.strip()
            if stmt:
                cursor.execute(stmt)
                count += 1
        
        conn.commit()
        return {'success': True, 'statements': count, 'file': filename}
    except Error as e:
        if conn:
            conn.rollback()
        return {'success': False, 'error': str(e), 'file': filename}
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()


def call_procedure(proc_name, args=(), out_params=0, commit=True):
    """
    Gọi stored procedure.
    
    Args:
        proc_name: tên stored procedure
        args: tuple tham số
        out_params: số lượng tham số OUT ở cuối
        commit: True nếu cần commit
    Returns:
        dict: { 'results': list[dict], 'out_params': tuple, 'affected_rows': int }
    """
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)

        # Gọi stored procedure
        result_args = cursor.callproc(proc_name, args)

        # Lấy kết quả trả về (nếu có SELECT trong procedure)
        results = []
        for result_set in cursor.stored_results():
            results.extend(result_set.fetchall())

        if commit:
            conn.commit()

        # Lấy tham số OUT (nếu có)
        if out_params > 0:
            if isinstance(result_args, dict):
                # Newer mysql-connector returns dict with keys like 'proc_name_argN'
                keys = sorted([k for k in result_args.keys() if k.startswith(f'{proc_name}_arg')])
                out_keys = keys[-out_params:]
                out_values = tuple(result_args[k] for k in out_keys)
            else:
                out_values = tuple(result_args[-out_params:])
        else:
            out_values = ()

        return {
            'results': results,
            'out_params': out_values,
            'affected_rows': cursor.rowcount
        }
    except Error as e:
        if conn and commit:
            conn.rollback()
        raise e
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()


def call_function(func_name, args=()):
    """
    Gọi MySQL function.
    
    Args:
        func_name: tên function
        args: tuple tham số
    Returns:
        Giá trị trả về của function
    """
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor()
        
        # Tạo câu SELECT gọi function
        placeholders = ', '.join(['%s'] * len(args))
        query = f"SELECT {func_name}({placeholders})"
        cursor.execute(query, args)
        
        result = cursor.fetchone()
        conn.commit()
        
        return result[0] if result else None
    except Error as e:
        if conn:
            conn.rollback()
        raise e
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()
