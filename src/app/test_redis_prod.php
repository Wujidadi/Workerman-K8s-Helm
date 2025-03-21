<?php

require_once 'vendor/autoload.php'; // 若使用 composer 安裝 redis 客戶端

use Predis\Client;

// Redis 設定
$host = 'redis-workerman-helm-master.redis-workerman-helm.svc.cluster.local';
$port = '6379';
$password = 'prod-redis-password';

// 建立 Redis 連線
try {
    $redis = new Client([
        'scheme'   => 'tcp',
        'host'     => $host,
        'port'     => $port,
        'password' => $password,
    ]);

    // 測試 SET
    $redis->set('test_key', 'Hello from PHP Redis Client');
    echo "✅ 成功寫入 Redis！" . PHP_EOL;

    // 測試 GET
    $value = $redis->get('test_key');
    echo "讀取 test_key: $value" . PHP_EOL;

} catch (Exception $e) {
    echo "❌ Redis 連線或操作失敗：" . $e->getMessage() . PHP_EOL;
}
