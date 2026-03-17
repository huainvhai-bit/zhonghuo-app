<?php
/**
 * 终活 App - 用户管理 API
 * 支持：注册、登录、密码重置、用户信息更新
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// 处理 OPTIONS 预检请求
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// 数据库配置
$db_config = [
    'host' => 'localhost',
    'name' => 'zhonghuo_db',
    'user' => 'zhonghuo_user',
    'pass' => 'Zhonghuo@2026'
];

// 响应函数
function json_response($data, $code = 200) {
    http_response_code($code);
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit();
}

// 获取 JSON 输入
$input = json_decode(file_get_contents('php://input'), true);
$action = $input['action'] ?? '';
$phone = $input['phone'] ?? '';
$password = $input['password'] ?? '';
$name = $input['name'] ?? '';
$verify_code = $input['verify_code'] ?? '';
$login_type = $input['login_type'] ?? 'password';

// 验证手机号格式
function validate_phone($phone) {
    return preg_match('/^1[3-9]\d{9}$/', $phone);
}

// 生成 token
function generate_token($user_id) {
    return bin2hex(random_bytes(32)) . '_' . time();
}

try {
    // 连接数据库
    $pdo = new PDO(
        "mysql:host={$db_config['host']};dbname={$db_config['name']};charset=utf8mb4",
        $db_config['user'],
        $db_config['pass'],
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
        ]
    );

    switch ($action) {
        case 'register':
            // 注册
            if (!validate_phone($phone)) {
                json_response(['success' => false, 'error' => '手机号格式不正确', 'code' => 'INVALID_PHONE'], 400);
            }
            
            if (strlen($password) < 6) {
                json_response(['success' => false, 'error' => '密码至少 6 位', 'code' => 'INVALID_PASSWORD'], 400);
            }
            
            if (empty($name)) {
                json_response(['success' => false, 'error' => '姓名不能为空', 'code' => 'INVALID_NAME'], 400);
            }
            
            // 测试模式：跳过验证码验证
            if (!defined('SKIP_VERIFY_CODE') || !SKIP_VERIFY_CODE) {
                if (empty($verify_code)) {
                    json_response(['success' => false, 'error' => '请输入验证码', 'code' => 'MISSING_CODE'], 400);
                }
                // TODO: 验证验证码
            }
            
            // 检查手机号是否已存在
            $stmt = $pdo->prepare("SELECT id FROM users WHERE phone = ?");
            $stmt->execute([$phone]);
            if ($stmt->fetch()) {
                json_response(['success' => false, 'error' => '该手机号已注册', 'code' => 'PHONE_EXISTS'], 400);
            }
            
            // 创建用户
            $user_id = 'user_' . bin2hex(random_bytes(16));
            $password_hash = password_hash($password, PASSWORD_DEFAULT);
            $created_at = date('Y-m-d H:i:s');
            
            $stmt = $pdo->prepare("
                INSERT INTO users (id, phone, name, password_hash, created_at, check_in_interval_hours)
                VALUES (?, ?, ?, ?, ?, 48)
            ");
            $stmt->execute([$user_id, $phone, $name, $password_hash, $created_at]);
            
            // 生成 token
            $token = generate_token($user_id);
            
            // 保存 token（简化版，实际应该存到 tokens 表）
            // 这里直接返回，验证时再检查
            
            json_response([
                'success' => true,
                'message' => '注册成功',
                'data' => [
                    'token' => $token,
                    'user_id' => $user_id,
                    'is_new' => true,
                    'user' => [
                        'id' => $user_id,
                        'name' => $name,
                        'phone' => $phone,
                        'check_in_interval' => 48
                    ]
                ]
            ], 201);
            break;

        case 'login':
            // 登录
            if (!validate_phone($phone)) {
                json_response(['success' => false, 'error' => '手机号格式不正确', 'code' => 'INVALID_PHONE'], 400);
            }
            
            if ($login_type === 'password') {
                if (empty($password)) {
                    json_response(['success' => false, 'error' => '请输入密码', 'code' => 'MISSING_PASSWORD'], 400);
                }
                
                // 查询用户
                $stmt = $pdo->prepare("SELECT * FROM users WHERE phone = ?");
                $stmt->execute([$phone]);
                $user = $stmt->fetch();
                
                if (!$user) {
                    json_response(['success' => false, 'error' => '用户不存在', 'code' => 'USER_NOT_FOUND'], 404);
                }
                
                // 验证密码
                if (!password_verify($password, $user['password_hash'])) {
                    json_response(['success' => false, 'error' => '密码错误', 'code' => 'INVALID_PASSWORD'], 401);
                }
                
            } else if ($login_type === 'verify_code') {
                // 验证码登录（简化版）
                if (empty($verify_code)) {
                    json_response(['success' => false, 'error' => '请输入验证码', 'code' => 'MISSING_CODE'], 400);
                }
                
                $stmt = $pdo->prepare("SELECT * FROM users WHERE phone = ?");
                $stmt->execute([$phone]);
                $user = $stmt->fetch();
                
                if (!$user) {
                    json_response(['success' => false, 'error' => '用户不存在', 'code' => 'USER_NOT_FOUND'], 404);
                }
                
                // TODO: 验证验证码
            }
            
            // 生成 token
            $token = generate_token($user['id']);
            
            // 更新最后登录时间
            $stmt = $pdo->prepare("UPDATE users SET last_login_at = NOW() WHERE id = ?");
            $stmt->execute([$user['id']]);
            
            json_response([
                'success' => true,
                'message' => '登录成功',
                'data' => [
                    'token' => $token,
                    'user_id' => $user['id'],
                    'user' => [
                        'id' => $user['id'],
                        'name' => $user['name'],
                        'phone' => $user['phone'],
                        'check_in_interval' => $user['check_in_interval_hours'] ?? 48,
                        'last_check_in_date' => $user['last_check_in_date'] ?? null
                    ]
                ]
            ]);
            break;

        case 'reset_password':
            // 重置密码
            if (!validate_phone($phone)) {
                json_response(['success' => false, 'error' => '手机号格式不正确', 'code' => 'INVALID_PHONE'], 400);
            }
            
            if (strlen($password) < 6) {
                json_response(['success' => false, 'error' => '密码至少 6 位', 'code' => 'INVALID_PASSWORD'], 400);
            }
            
            // 验证验证码
            if (empty($verify_code)) {
                json_response(['success' => false, 'error' => '请输入验证码', 'code' => 'MISSING_CODE'], 400);
            }
            
            // 查询用户
            $stmt = $pdo->prepare("SELECT id FROM users WHERE phone = ?");
            $stmt->execute([$phone]);
            $user = $stmt->fetch();
            
            if (!$user) {
                json_response(['success' => false, 'error' => '用户不存在', 'code' => 'USER_NOT_FOUND'], 404);
            }
            
            // 更新密码
            $password_hash = password_hash($password, PASSWORD_DEFAULT);
            $stmt = $pdo->prepare("UPDATE users SET password_hash = ? WHERE id = ?");
            $stmt->execute([$password_hash, $user['id']]);
            
            json_response([
                'success' => true,
                'message' => '密码重置成功'
            ]);
            break;

        case 'get_user_info':
            // 获取用户信息（需要 token）
            $token = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
            if (empty($token)) {
                json_response(['success' => false, 'error' => '未授权', 'code' => 'UNAUTHORIZED'], 401);
            }
            
            // TODO: 验证 token
            
            $stmt = $pdo->prepare("SELECT id, name, phone, created_at, check_in_interval_hours, last_check_in_date FROM users WHERE phone = ?");
            $stmt->execute([$phone]);
            $user = $stmt->fetch();
            
            if (!$user) {
                json_response(['success' => false, 'error' => '用户不存在', 'code' => 'USER_NOT_FOUND'], 404);
            }
            
            json_response([
                'success' => true,
                'data' => $user
            ]);
            break;

        default:
            json_response(['success' => false, 'error' => '未知操作', 'code' => 'INVALID_ACTION'], 400);
    }

} catch (PDOException $e) {
    json_response([
        'success' => false,
        'error' => '数据库错误：' . $e->getMessage(),
        'code' => 'DATABASE_ERROR'
    ], 500);
} catch (Exception $e) {
    json_response([
        'success' => false,
        'error' => '服务器错误：' . $e->getMessage(),
        'code' => 'SERVER_ERROR'
    ], 500);
}
