/* ============================================================
   BTL2 — HỆ THỐNG ĐẶT VÉ RẠP CHIẾU PHIM
   File: static/js/main.js
   Mục đích: JavaScript chung cho toàn ứng dụng
   ============================================================ */

// ---- LOADING SPINNER ----
function showLoading() {
    const overlay = document.getElementById('loadingOverlay');
    if (overlay) {
        overlay.classList.remove('d-none');
    }
}

function hideLoading() {
    const overlay = document.getElementById('loadingOverlay');
    if (overlay) {
        overlay.classList.add('d-none');
    }
}

// ---- AUTO-DISMISS FLASH MESSAGES (sau 5 giây) ----
document.addEventListener('DOMContentLoaded', function () {
    const alerts = document.querySelectorAll('.alert-dismissible');
    alerts.forEach(function (alert) {
        setTimeout(function () {
            const bsAlert = bootstrap.Alert.getOrCreateInstance(alert);
            if (bsAlert) {
                bsAlert.close();
            }
        }, 5000);
    });
});

// ---- FORMAT VND ----
function formatVND(amount) {
    if (isNaN(amount)) return '0 VND';
    return parseInt(amount).toLocaleString('vi-VN') + ' VND';
}

// ---- DEBOUNCE HELPER ----
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// ---- TOOLTIP INITIALIZATION (Bootstrap) ----
document.addEventListener('DOMContentLoaded', function () {
    const tooltipTriggerList = [].slice.call(
        document.querySelectorAll('[data-bs-toggle="tooltip"]')
    );
    tooltipTriggerList.map(function (el) {
        return new bootstrap.Tooltip(el);
    });
});
