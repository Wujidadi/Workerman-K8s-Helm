<?php

$host = 'postgres-workerman-helm-postgresql.postgres-workerman-helm.svc.cluster.local';
$port = '5432';
$dbname = 'workermandb';
$user = 'produser';
$password = 'prodpassword';

$dsn = "pgsql:host=$host;port=$port;dbname=$dbname";

try {
    $pdo = new PDO($dsn, $user, $password, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
    echo "✅ 成功連線到 PostgreSQL！" . PHP_EOL;

    // 測試執行一個查詢（可略過）
    $stmt = $pdo->query('SELECT version()');
    $version = $stmt->fetchColumn();
    echo "PostgreSQL 版本：$version" . PHP_EOL;
} catch (PDOException $e) {
    echo "❌ 連線失敗：" . $e->getMessage() . PHP_EOL;
}
