include .env
.PHONY: isucon14 isucon14-bench

ssh: isucon14
bench: isucon14-bench

NGINX_LOG := ./logs/nginx/access.log
SERVER_NGINX_LOG := ./logs/nginx/access.log

SERVER_NGINX_PATH:=/etc/nginx


# --------- local ---------

isucon14:
	ssh -i "~/.ssh/isucon.pem" ubuntu@$(ISUCON_HOST)

isucon14-bench:
	docker run --rm -it -v "$(shell pwd):/work" -w /work ubuntu:22.04 \
		./isucon14/bench run . \
		--addr $(ISUCON_IP):443 \
		--target https://isuride.xiv.isucon.net \
		--payment-url http://127.0.0.1:12346 \
		--payment-bind-port 12346 \
		2>&1 | tee isucon14/logs/bench/bench_$$(date +'%Y%m%d_%H%M%S').log

.PHONY: alp
alp:
	alp lstv --file=$(NGINX_LOG)


# --------- server ---------
.PHONY: pull-conf
pull-conf: pull-nginx

.PHONY: deploy-conf
deploy-conf: deploy-nginx

.PHONY: restart
restart:
	sudo systemctl daemon-reload
	sudo systemctl restart nginx

.PHONY: pull-logs
pull-logs:
	$(eval when := $(shell date "+%s"))
	mkdir -p ~/logs/$(when)
	sudo test -f $(SERVER_NGINX_LOG) && \
		sudo mv -f $(SERVER_NGINX_LOG) ~/logs/$(when)/ || true

# -----

.PHONY: install-tools
install-tools:
	sudo apt update
	sudo apt upgrade

.PHONY: deploy-nginx
deploy-nginx:
	sudo cp -R ./etc/nginx/* $(SERVER_NGINX_PATH)

.PHONY: pull-nginx
pull-nginx:
	sudo cp -R $(SERVER_NGINX_PATH)/* ./etc/nginx

.PHONY: reload-nginx
reload-nginx:
	sudo nginx -t
	sudo systemctl reload nginx
