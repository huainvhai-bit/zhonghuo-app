-- 终活 App 数据库初始化脚本
-- 在服务器上执行：mysql -u root -p < init_zhonghuo_db.sql

-- 创建数据库
CREATE DATABASE IF NOT EXISTS zhonghuo_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 创建用户
CREATE USER IF NOT EXISTS 'zhonghuo_user'@'localhost' IDENTIFIED BY 'Zhonghuo@2026';
GRANT ALL PRIVILEGES ON zhonghuo_db.* TO 'zhonghuo_user'@'localhost';
FLUSH PRIVILEGES;

-- 使用数据库
USE zhonghuo_db;

-- 创建用户表
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(64) PRIMARY KEY,
    phone VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login_at DATETIME NULL,
    last_check_in_date DATETIME NULL,
    check_in_interval_hours INT DEFAULT 48,
    notifications_enabled TINYINT(1) DEFAULT 1,
    cloud_sync_enabled TINYINT(1) DEFAULT 0,
    INDEX idx_phone (phone),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 创建时光胶囊表
CREATE TABLE IF NOT EXISTS capsules (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL,
    title VARCHAR(200) NOT NULL,
    content TEXT,
    media_type ENUM('text', 'image', 'audio', 'video') DEFAULT 'text',
    media_url VARCHAR(500),
    open_at DATETIME NOT NULL,
    is_opened TINYINT(1) DEFAULT 0,
    created_at DATETIME NOT NULL,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_open_at (open_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 创建遗嘱模板表
CREATE TABLE IF NOT EXISTS will_templates (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    category VARCHAR(50),
    is_completed TINYINT(1) DEFAULT 0,
    created_at DATETIME NOT NULL,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 创建资产表
CREATE TABLE IF NOT EXISTS assets (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL,
    name VARCHAR(200) NOT NULL,
    type VARCHAR(50) NOT NULL,
    account VARCHAR(200),
    password_hint VARCHAR(255),
    notes TEXT,
    value DECIMAL(12,2),
    created_at DATETIME NOT NULL,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 创建见证人表
CREATE TABLE IF NOT EXISTS witnesses (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    relation VARCHAR(50),
    is_confirmed TINYINT(1) DEFAULT 0,
    confirmed_at DATETIME NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 创建紧急联系人表
CREATE TABLE IF NOT EXISTS emergency_contacts (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    relation VARCHAR(50),
    priority INT DEFAULT 1,
    created_at DATETIME NOT NULL,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 创建签到记录表
CREATE TABLE IF NOT EXISTS check_in_records (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL,
    check_in_date DATETIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_date (user_id, check_in_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 插入测试用户（可选）
-- 密码：test123456
INSERT INTO users (id, phone, name, password_hash, created_at, check_in_interval_hours)
VALUES (
    'user_test001',
    '13800138006',
    '测试用户',
    '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    NOW(),
    48
) ON DUPLICATE KEY UPDATE name=VALUES(name);

-- 密码：test123
INSERT INTO users (id, phone, name, password_hash, created_at, check_in_interval_hours)
VALUES (
    'user_test002',
    '13800138008',
    '测试用户 8',
    '$2y$10$4N8xVxY5k6PqGz8h9nV7xOZGk5bF2qR8sT1uW3vX4yZ5aB6cD7eF8',
    NOW(),
    48
) ON DUPLICATE KEY UPDATE name=VALUES(name);
