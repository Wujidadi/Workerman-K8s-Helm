<?php
use Workerman\Worker;
use Workerman\Connection\TcpConnection;
use Workerman\Protocols\Http\Request;
require_once __DIR__ . '/vendor/autoload.php';

// 創建一個 Worker 監聽 2345 端口，使用 HTTP 協議通訊
$http_worker = new Worker("http://0.0.0.0:2345");

// 啟動 4 個進程對外提供服務
$http_worker->count = 4;

// 接收到瀏覽器發送的數據時，回覆訊息給瀏覽器
$http_worker->onMessage = function(TcpConnection $connection, Request $request)
{
    // 向瀏覽器發送訊息
    $connection->send('愛城戀太郎是永遠的超人！');
};

// 運行 worker
Worker::runAll();
