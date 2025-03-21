.SILENT:

.PHONY: \
	helm \
	k8s-secret \
	save-tag \
	zsh-history \
	build \
	load \
	deploy \
	deploy-dev \
	deploy-prod \
	deploy-postgres-dev \
	deploy-postgres-prod \
	deploy-redis-dev \
	deploy-redis-prod \
	create-cluster \
	delete-cluster \
	install-ingress \
	uninstall-ingress \
	reload \
	restart \
	startup \
	startup-dev \
	startup-prod \
	clean \
	clean-postgres \
	clean-redis \
	show-all \
	forward-db \
	forward-redis \
	forward-all \
	list-clusters \
	list-pods \
	get-containers \
	shell \
	shell-pick \
	shutdown \
	cleanup-namespaces

# 專案參數
REPOSITORY := wujidadi/workerman
CLUSTER_NAME := workerman-k8s
RELEASE_NAME := workerman-helm
CHART_NAME := workerman
LABEL_KEY := app

# 版本參數
BUILD_TAG_FILE := .build_tag
TAG := $(shell [ -f $(BUILD_TAG_FILE) ] && cat $(BUILD_TAG_FILE) || date +%Y%m%d%H%M%S)

# Ingress 參數
INGRESS_NAMESPACE := workerman-ingress
INGRESS_CLASS := workerman-ingress-nginx
HTTP_PORT := 30740
HTTPS_PORT := 30743

# PostgreSQL 參數
PG_HELM_VERSION := 16.5.5
PG_RELEASE_NAME := postgres-workerman-helm
PG_CHART_NAME := postgresql
PG_PORT := 5432
PG_HOST_PORT := 54319

# Redis 參數
REDIS_HELM_VERSION := 20.11.3
REDIS_RELEASE_NAME := redis-workerman-helm
REDIS_CHART_NAME := redis
REDIS_SUB_NAME := master
REDIS_PORT := 6379
REDIS_HOST_PORT := 63789
REDIS_SECRET := redis-workerman-secret  # 要和 charts/redis/values-*.yaml 的 auth.existingSecret 相同
REDIS_PROD_PASSWORD := prod-redis-password

# 建構映像檔
build: save-tag zsh-history
	CMD="docker build -t $(REPOSITORY):$(shell cat $(BUILD_TAG_FILE)) ."; \
	echo "👉 $$CMD"; \
	eval $$CMD

# Helm 環境建置
helm:
	CMD="helm repo add bitnami https://charts.bitnami.com/bitnami; \
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx; \
	helm repo update; \
	helm pull bitnami/postgresql --version $(PG_HELM_VERSION) --untar -d charts/; \
	helm create charts/$(CHART_NAME); \
	helm pull bitnami/redis --untar --version $(REDIS_HELM_VERSION) -d charts/"; \
	echo "👉 $$CMD"; \
	eval $$CMD

# 使用 Kubernetes Secrets 建立 Redis 生產環境所需的密碼
k8s-secret:
	CMD="kubectl create namespace $(REDIS_RELEASE_NAME) --dry-run=client -o yaml | kubectl apply -f - || true; \
	kubectl create secret generic $(REDIS_SECRET) --from-literal=redis-password=\"$(REDIS_PROD_PASSWORD)\" -n $(REDIS_RELEASE_NAME) || true"; \
	echo "👉 $$CMD"; \
	eval $$CMD

# 產生 build tag
save-tag:
	echo "🔸 Generating build tag..."; \
	BUILD_TAG=$$(date +%Y%m%d%H%M%S); \
	echo $$BUILD_TAG > $(BUILD_TAG_FILE); \
	echo "🔸 Build tag saved: $$BUILD_TAG"

# 建立 Zsh 歷史記錄掛載點
zsh-history:
	CMD="touch zsh/root.zsh_history"; \
	echo "👉 $$CMD"; \
	eval $$CMD

# 將映像檔載入 Kind
load:
	CMD="kind load docker-image $(REPOSITORY):$(TAG) --name $(CLUSTER_NAME)"; \
	echo "👉 $$CMD"; \
	eval $$CMD

# 部署 Workerman App（預設）
deploy:
	CMD="helm upgrade --install $(RELEASE_NAME) charts/$(CHART_NAME) --namespace $(RELEASE_NAME) --create-namespace --values charts/$(CHART_NAME)/values-dev.yaml --set image.repository=$(REPOSITORY) --set image.tag=$(TAG)"; \
	echo "👉 $$CMD"; \
	eval $$CMD

# 部署 Workerman App（開發環境）
deploy-dev:
	CMD="helm upgrade --install $(RELEASE_NAME) charts/$(CHART_NAME) --namespace $(RELEASE_NAME) --create-namespace --values charts/$(CHART_NAME)/values-dev.yaml --set image.repository=$(REPOSITORY) --set image.tag=$(TAG)"; \
	echo "👉 $$CMD"; \
	eval $$CMD

# 部署 Workerman App（生產環境）
deploy-prod:
	CMD="helm upgrade --install $(RELEASE_NAME) charts/$(CHART_NAME) --namespace $(RELEASE_NAME) --create-namespace --values charts/$(CHART_NAME)/values-prod.yaml --set image.repository=$(REPOSITORY) --set image.tag=$(TAG)"; \
	echo "👉 $$CMD"; \
	eval $$CMD

# 部署 PostgreSQL（開發環境）
deploy-postgres-dev:
	CMD="helm upgrade --install $(PG_RELEASE_NAME) charts/$(PG_CHART_NAME) --namespace $(PG_RELEASE_NAME) --create-namespace -f charts/$(PG_CHART_NAME)/values-dev.yaml"; \
	echo "👉 $$CMD"; \
	eval $$CMD

# 部署 PostgreSQL（生產環境）
deploy-postgres-prod:
	CMD="helm upgrade --install $(PG_RELEASE_NAME) charts/$(PG_CHART_NAME) --namespace $(PG_RELEASE_NAME) --create-namespace -f charts/$(PG_CHART_NAME)/values-prod.yaml"; \
	echo "👉 $$CMD"; \
	eval $$CMD

# 部署 Redis（開發環境）
deploy-redis-dev:
	CMD="helm upgrade --install $(REDIS_RELEASE_NAME) charts/$(REDIS_CHART_NAME) --namespace $(REDIS_RELEASE_NAME) --create-namespace -f charts/$(REDIS_CHART_NAME)/values-dev.yaml"; \
	echo "👉 $$CMD"; \
	eval $$CMD

# 部署 Redis（生產環境）
deploy-redis-prod: k8s-secret
	@CMD="helm upgrade --install $(REDIS_RELEASE_NAME) charts/$(REDIS_CHART_NAME) --namespace $(REDIS_RELEASE_NAME) --create-namespace -f charts/$(REDIS_CHART_NAME)/values-prod.yaml"; \
	echo "👉 $$CMD"; \
	eval $$CMD

# 建立 cluster
create-cluster:
	CMD="kind create cluster --config kind-config.yaml --name $(CLUSTER_NAME)"; \
	echo "👉 $$CMD"; \
	eval $$CMD

# 刪除 cluster
delete-cluster:
	CMD="kind delete cluster --name $(CLUSTER_NAME)"; \
	echo "👉 $$CMD"; \
	eval $$CMD

# 安裝 Ingress-nginx 並等候就緒，結束後提示 URL 範本
install-ingress:
	CMD="helm upgrade --install $(INGRESS_NAMESPACE) ingress-nginx/ingress-nginx \
		--namespace $(INGRESS_NAMESPACE) --create-namespace \
		--set controller.service.type=NodePort \
		--set controller.service.nodePorts.http=$(HTTP_PORT) \
		--set controller.service.nodePorts.https=$(HTTPS_PORT) \
		--set controller.ingressClassResource.name=$(INGRESS_CLASS) \
		--set controller.ingressClassResource.controllerValue=\"k8s.io/$(INGRESS_CLASS)\" && \
	kubectl wait --namespace $(INGRESS_NAMESPACE) --for=condition=Ready pod -l app.kubernetes.io/component=controller --timeout=600s"; \
	echo "👉 $$CMD"; \
	eval $$CMD

# 清除 Ingress-nginx
uninstall-ingress:
	CMD="kubectl delete ns $(INGRESS_NAMESPACE) || true"; \
	echo "👉 $$CMD"; \
	eval $$CMD

# 重載服務（不刪除 cluster）
reload:
	CMD="make build && make load && make deploy"; \
	echo "👉 $$CMD"; \
	eval $$CMD

# 滾動重啟（不重建）
restart:
	CMD="kubectl rollout restart deployment $(RELEASE_NAME)-$(CHART_NAME)"; \
	echo "👉 $$CMD"; \
	eval $$CMD

# 一鍵完整重部署（預設）
startup:
	CMD="make delete-cluster && make create-cluster && make build && make load && make deploy && make deploy-postgres-dev && make deploy-redis-dev && make install-ingress"; \
	echo "👉 $$CMD"; \
	eval $$CMD

# 一鍵完整重部署（開發環境）
startup-dev:
	CMD="make delete-cluster && make create-cluster && make build && make load && make deploy-dev && make deploy-postgres-dev && make deploy-redis-dev && make install-ingress"; \
	echo "👉 $$CMD"; \
	eval $$CMD

# 一鍵完整重部署（生產環境）
startup-prod:
	CMD="make delete-cluster && make create-cluster && make build && make load && make deploy-prod && make deploy-postgres-prod && make clean-redis && make k8s-secret && make deploy-redis-prod && make install-ingress"; \
	echo "👉 $$CMD"; \
	eval $$CMD

# 清除 Workerman Helm release
clean:
	CMD="helm uninstall $(RELEASE_NAME) || true"; \
	echo "👉 $$CMD"; \
	eval $$CMD

# 清除 PostgreSQL Helm release
clean-postgres:
	CMD="helm uninstall $(PG_RELEASE_NAME) || true"; \
	echo "👉 $$CMD"; \
	eval $$CMD

## 清除 Redis Helm release
clean-redis:
	@CMD="helm uninstall $(REDIS_RELEASE_NAME) -n $(REDIS_RELEASE_NAME) || true"; \
	echo "👉 $$CMD"; \
	eval $$CMD

# 一鍵顯示所有 Helm Release、Pods、Services、Ingress 狀態
show-all:
	echo "✅ 目前 Helm Releases:" && helm list -A
	echo "✅ 目前 Pods 狀態:" && kubectl get pods --all-namespaces
	echo "✅ 目前 Services:" && kubectl get svc --all-namespaces
	echo "✅ 目前 Ingress:" && kubectl get ingress -A

# 將 PostgreSQL DB 埠暫時暴露給宿主
forward-db:
	CMD="kubectl port-forward svc/$(PG_RELEASE_NAME)-$(PG_CHART_NAME) $(PG_HOST_PORT):$(PG_PORT) --context kind-$(CLUSTER_NAME)"; \
	echo "👉 $$CMD"; \
	eval $$CMD

# 將 Redis 埠暫時暴露給宿主
forward-redis:
	CMD="kubectl port-forward svc/$(REDIS_RELEASE_NAME)-$(REDIS_SUB_NAME) $(REDIS_HOST_PORT):$(REDIS_PORT) --context kind-$(CLUSTER_NAME)"; \
	echo "👉 $$CMD"; \
	eval $$CMD

# 同時 Forward DB 及 Redis
forward-all:
	make forward-db & make forward-redis &
	echo "✅ PostgreSQL 已 forward 至 localhost:$(PG_HOST_PORT)"
	echo "✅ Redis 已 forward 至 localhost:$(REDIS_HOST_PORT)"

# 查看 Kubernetes 集群狀態
list-clusters:
	CMD="kind get clusters"; \
	echo "👉 $$CMD"; \
	eval $$CMD

# 查看 Kubernetes Pod 狀態
list-pods:
	CMD="kubectl get pods -n $(RELEASE_NAME) && kubectl get pods -n $(PG_RELEASE_NAME) && kubectl get pods -n $(REDIS_RELEASE_NAME)"; \
	echo "👉 $$CMD"; \
	eval $$CMD

# 列出 Pod 的中容器名稱
get-containers:
	@PODS=$$(kubectl get pods -n workerman-helm -o jsonpath="{.items[*].metadata.name}"); \
	for POD in $$PODS; do \
		echo "🔎 Pod: $$POD"; \
		CONTAINERS=$$(kubectl get pod $$POD -n workerman-helm -o jsonpath="{.spec.containers[*].name}"); \
		echo "👉 Containers: $$CONTAINERS"; \
		echo ""; \
	done

# 自動偵測 Pod + Container 並進入 shell
shell:
	@PODS=$$(kubectl get pods -n workerman-helm -o jsonpath="{.items[*].metadata.name}"); \
	for POD in $$PODS; do \
		CONTAINERS=$$(kubectl get pod $$POD -n workerman-helm -o jsonpath="{.spec.containers[*].name}"); \
		for CONTAINER in $$CONTAINERS; do \
			echo "嘗試進入 Pod: $$POD, Container: $$CONTAINER ..."; \
			if kubectl exec -it $$POD -n workerman-helm -c $$CONTAINER -- /bin/zsh 2>/dev/null; then \
				echo "✅ 已成功進入 Pod: $$POD, Container: $$CONTAINER"; \
				break 2; \
			else \
				echo "⚠️ 無法進入 Pod: $$POD, Container: $$CONTAINER，嘗試下一個..."; \
			fi; \
		done; \
	done

# 多 Pod 手動選擇 shell
shell-pick:
	@bash -c '\
		POD_LIST=$$(kubectl get pods -n workerman-helm -l $(LABEL_KEY)=$(CHART_NAME) -o jsonpath="{.items[*].metadata.name}"); \
		PS3="請選擇要進入的 Pod："; \
		select SELECTED_POD in $$POD_LIST; do \
			[ -n "$$SELECTED_POD" ] && break; \
		done; \
		CONTAINERS=$$(kubectl get pod $$SELECTED_POD -n workerman-helm -o jsonpath="{.spec.containers[*].name}"); \
		CONTAINER_COUNT=$$(echo $$CONTAINERS | wc -w); \
		if [ $$CONTAINER_COUNT -gt 1 ]; then \
			PS3="此 Pod 有多個容器，請選擇 Container："; \
			select SELECTED_CONTAINER in $$CONTAINERS; do \
				[ -n "$$SELECTED_CONTAINER" ] && break; \
			done; \
		else \
			SELECTED_CONTAINER=$$(echo $$CONTAINERS | awk "{print \$$1}"); \
		fi; \
		echo "👉 正在檢查可用 shell ..."; \
		SHELL_CMD=$$(kubectl exec $$SELECTED_POD -n workerman-helm -c $$SELECTED_CONTAINER -- sh -c "command -v zsh || command -v bash || command -v sh"); \
		if [ -z "$$SHELL_CMD" ]; then \
			read -p "找不到預設 shell，請自行輸入要執行的指令（例如 /bin/sh）： " SHELL_CMD; \
		fi; \
		CMD="kubectl exec -it $$SELECTED_POD -n workerman-helm -c $$SELECTED_CONTAINER -- $$SHELL_CMD"; \
		echo "👉 $$CMD"; \
		eval $$CMD \
	'

# 關閉並清理所有資源
shutdown:
	@read -p "⚠️ 確定要關閉所有服務並刪除 cluster 嗎？(y/N): " CONFIRM && \
	if [ "$$CONFIRM" = "y" ] || [ "$$CONFIRM" = "Y" ]; then \
		CMD="helm uninstall $(RELEASE_NAME) -n $(RELEASE_NAME) && helm uninstall $(PG_RELEASE_NAME) -n $(PG_RELEASE_NAME) && helm uninstall $(REDIS_RELEASE_NAME) -n $(REDIS_RELEASE_NAME) && kubectl delete ns $(INGRESS_NAMESPACE) || true && kind delete cluster --name $(CLUSTER_NAME)"; \
		echo "👉 開始關閉所有服務..."; \
		echo "👉 $$CMD"; \
		eval $$CMD; \
		echo "✅ 所有服務已關閉"; \
	else \
		echo "❎ 已取消關閉動作"; \
	fi

# 自動清理孤兒 namespaces
cleanup-namespaces:
	CMD="kubectl get ns | grep -E 'workerman|redis|postgres' | awk '{print \$$1}' | xargs -I {} kubectl delete ns {}"; \
	echo "👉 $$CMD"; \
	eval $$CMD
