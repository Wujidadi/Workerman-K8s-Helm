# Workerman-K8s-Helm

## Makefile

### makefile 支援指令

| 指令名稱                    | 說明                                                    |
| --------------------------- | ------------------------------------------------------- |
| `make helm`                 | Helm 環境建置                                           |
| `make k8s-secret`           | 使用 Kubernetes Secrets 建立 Redis 生產環境所需的密碼   |
| `make save-tag`             | 產生 build tag                                          |
| `make zsh-history`          | 建立 Zsh 歷史記錄掛載點                                 |
| `make build`                | 建立 Docker 映像檔                                      |
| `make load`                 | 載入映像檔到 Kind                                       |
| `make deploy`               | 預設部署 Workerman 應用（使用開發環境設定）             |
| `make deploy-dev`           | 部署 Workerman 應用（開發環境）                         |
| `make deploy-prod`          | 部署 Workerman 應用（生產環境）                         |
| `make deploy-postgres-dev`  | 部署 PostgreSQL（開發環境）                             |
| `make deploy-postgres-prod` | 部署 PostgreSQL（生產環境）                             |
| `make deploy-redis-dev`     | 部署 Redis（開發環境）                                  |
| `make deploy-redis-prod`    | 部署 Redis（生產環境）                                  |
| `make create-cluster`       | 建立本地 K8s Cluster                                    |
| `make delete-cluster`       | 刪除 Cluster                                            |
| `make install-ingress`      | 安裝 Ingress-nginx 並等候就緒，結束後提示 URL 範本      |
| `make uninstall-ingress`    | 清除 Ingress-nginx                                      |
| `make reload`               | 重建映像、更新並部署                                    |
| `make restart`              | 滾動重啟 Pod                                            |
| `make startup`              | 一鍵完整重部署（預設模式）                              |
| `make startup-dev`          | 一鍵完整重部署（開發環境版）                            |
| `make startup-prod`         | 一鍵完整重部署（生產環境版）                            |
| `make clean`                | 清除 Workerman Helm release                             |
| `make clean-postgres`       | 清除 PostgreSQL Helm release                            |
| `make clean-redis`          | 清除 Redis Helm release                                 |
| `make show-all`             | 一鍵顯示所有 Helm Release、Pods、Services、Ingress 狀態 |
| `make forward-db`           | 將 PostgreSQL DB 埠暫時暴露給宿主                       |
| `make forward-redis`        | 將 Redis 埠暫時暴露給宿主                               |
| `make forward-all`          | 同時 Forward DB 及 Redis                                |
| `make list-clusters`        | 查看 Kubernetes 集群狀態（通用指令）                    |
| `make list-pods`            | 查看 Kubernetes Pod 狀態                                |
| `make get-containers`       | 列出 Pod 的中容器名稱                                   |
| `make shell`                | 自動偵測 Pod + Container 並進入 shell                   |
| `make shell-pick`           | 多 Pod 手動選擇 shell                                   |
| `make shutdown`             | 關閉並刪除所有 Helm release 與 Cluster                  |

---

## Workerman

- `makefile` 中的 `CHART_NAME` 必須與 `charts/workerman/Chart.yaml` 裡的 `name` 相同。
- `charts/workerman/values.yaml` 裡的 `image.repository` 和 `image.tag` 只是預設值，實際部署時會被 `makefile` 中 `--set image.repository` 和 `--set image.tag` 的值所覆蓋。
- 如果只是修改 `src/app` 下的 Workerman 應用程式碼，執行 `make restart` 即可讓容器重啟並套用最新程式。
- 如果修改了 `Dockerfile`、底層 image 或是 `src/app/start.php` 這類入口設定，需要執行 `make reload`（build → load → deploy）。
- 若是要整個重新初始化（例如大版本更新、Kubernetes 設定異動），執行 `make startup`，會重建 Cluster、重新部署所有服務。
- 執行 `make startup/startup-dev/startup-prod` 運行或重啟全部服務，`make shutdown` 關閉並刪除所有服務。

---

## Kind

| 容器埠號 | 宿主埠號 |
| :------: | :------: |
|    80    |   740    |
|   443    |   743    |

---

## Helm

```bash
helm search repo bitnami/postgresql # 查看 bitnami/postgresql 最新版
helm search repo bitnami/redis # 查看 bitnami/redis 最新版
```

其他指令都寫在 `make helm` 了（見 `makefile`）

---

## Kubernetes Secrets

寫在 `make k8s-secret` 了（見 `makefile`）
> 跑生產模式前一定要先產生 Kubernetes Secrets (已加到 `make deploy-redis-prod` 前面)

---

## 啟動服務及檢測

```bash
# 若未建置過 Helm 須先執行
make helm

# 一鍵啟動開發環境
make startup-dev  # 也可以用 make startup

# 檢查 Workman App 是否正常
kubectl get pods -n workerman-helm
# 若此處不正常，可先檢查 log
kubectl logs $(kubectl get pods -n workerman-helm -o jsonpath="{.items[0].metadata.name}") -n workerman-helm
# 若 log 無輸出，再用 describe 查看詳情
kubectl describe pod $(kubectl get pods -n workerman-helm -o jsonpath="{.items[0].metadata.name}") -n workerman-helm

# 檢查 PostgreSQL 是否正常
kubectl get pods -n postgres-workerman-helm

# 檢查 Redis 是否正常
kubectl get pods -n redis-workerman-helm
kubectl get svc -n redis-workerman-helm

# 查看 Ingress
kubectl get ingress -n workerman-helm
make show-all | grep ingress
```

### 以開發模式下的使用者密碼為例，檢測資料庫設定是否正確

```bash
export POSTGRES_PASSWORD=$(kubectl get secret --namespace default postgres-helm-postgresql -o jsonpath="{.data.password}" | base64 -d)
echo $POSTGRES_PASSWORD
```

### 在 cluster 中用 PostgreSQL client 測試連線

```bash
kubectl run postgres-client --rm --tty -i --restart='Never' --namespace default \
 --image docker.io/bitnami/postgresql:17.4.0-debian-12-r10 \
 --env="PGPASSWORD=$POSTGRES_PASSWORD" \
 --command -- psql --host postgres-helm-postgresql -U devuser -d workermandb -p 5432
```

應可看到 PostgreSQL 提示符：
```
workermandb=>
```
也有可能先看到一行
```
If you don't see a command prompt, try pressing enter.
```
這時先按一下 Enter 就可以了。

---

### 測試 Workerman 與 PostgreSQL 的溝通是否順暢

```bash
# 開發環境
make startup # startup-dev 也可以，因為 test_pgsql.php 吃的是開發環境的資料庫設定
make shell
php test_pgsql_dev.php

# 生產環境
make startup-prod
make shell
php test_pgsql_prod.php
```

預期可見：
```
✅ 成功連線到 PostgreSQL！
PostgreSQL 版本：PostgreSQL 17.4 on aarch64-unknown-linux-gnu, compiled by gcc (Debian 12.2.0-14) 12.2.0, 64-bit
```

---

### 測試 Workerman 與 Redis 的溝通是否順暢

```bash
# 開發環境
make startup # startup-dev 也可以，因為 test_pgsql.php 吃的是開發環境的資料庫設定
make shell
php test_redis_dev.php

# 生產環境
make startup-prod
make shell
php test_redis_prod.php
```

預期可見：
```
✅ 成功寫入 Redis！Î
讀取 test_key: Hello from PHP Redis Client
```

---

## 建議訪問路由

由於本地 Ingress Controller 的 Service 非 LoadBalancer 或 HostNetwork，必須使用域名 + 埠號的方式訪問：

| 環境     | 訪問網址                                                                    |
| -------- | --------------------------------------------------------------------------- |
| 開發環境 | http://workerman-dev.localhost:740<br />https://workerman-dev.localhost:743 |
| 生產環境 | https://workerman.localhost:743<br />http://workerman.localhost:740         |

> 特別注意：頂級域名 `local` 會有 mDNS (Multicast DNS) 阻塞問題導致緩慢，在 macOS 上載入頁面可能會慢至 10 秒以上，即使是本機測試環境亦不應使用。
