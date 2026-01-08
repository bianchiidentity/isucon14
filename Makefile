include .env
.PHONY: isucon14 isucon14-bench

ssh: isucon14
bench: isucon14-bench

NGINX_LOG := ./logs/nginx/access.log
SERVER_NGINX_LOG := /var/log/nginx/access.log
SERVER_DB_LOG := /var/log/mysql/mysql-slow.log

SERVER_NGINX_PATH:=/etc/nginx
SERVER_DB_PATH:=/etc/mysql



# --------- local ---------

isucon14:
	ssh -i "~/.ssh/isucon.pem" ubuntu@$(ISUCON_HOST)

isucon14-bench:
	docker run --rm -it -v "$(shell pwd):/work" -w /work ubuntu:22.04 \
		./bench run . \
		--addr $(ISUCON_IP):443 \
		--target https://isuride.xiv.isucon.net \
		--payment-url http://127.0.0.1:12346 \
		--payment-bind-port 12346 \
		2>&1 | tee logs/bench/bench_$$(date +'%Y%m%d_%H%M%S').log

.PHONY: alp
alp:
	@for d in logs/*; do \
	  log="$$d/access.log"; \
	  out="$$d/alp.log"; \
	  if [ -f "$$log" ] && [ ! -f "$$out" ]; then \
	    echo "alp processing: $$log"; \
	    alp ltsv --file="$$log" --sort=sum --reverse > "$$out"; \
	  else \
	    echo "skip: $$d"; \
	  fi; \
	done

.PHONY: slow-query
slow-query:
	sudo pt-query-digest $(DB_SLOW_LOG)

# --------- server ---------
.PHONY: pull-conf
pull-conf: pull-nginx pull-db

.PHONY: deploy-conf
deploy-conf: deploy-nginx deploy-db

.PHONY: restart
restart:
	sudo systemctl daemon-reload
	sudo systemctl restart nginx
	sudo systemctl restart mysql

.PHONY: pull-logs
pull-logs:
	$(eval when := $(shell date "+%s"))
	mkdir -p ~/logs/$(when)
	sudo test -f $(SERVER_NGINX_LOG) && \
		sudo mv -f $(SERVER_NGINX_LOG) ~/logs/$(when)/ || true
	sudo test -f $(SERVER_DB_LOG) && \
		sudo mv -f $(SERVER_DB_LOG) ~/logs/mysql/$(when)/ || echo ""


# -----

.PHONY: install-tools
install-tools:
	sudo apt update
	sudo apt upgrade

.PHONY: pull-nginx
pull-nginx:
	sudo cp -R $(SERVER_NGINX_PATH)/* ./etc/nginx
	sudo chown $(USER) -R ./etc/nginx

.PHONY: deploy-nginx
deploy-nginx:
	sudo cp -R ./etc/nginx/* $(SERVER_NGINX_PATH)

.PHONY: reload-nginx
reload-nginx:
	sudo nginx -t
	sudo systemctl reload nginx

.PHONY: pull-db
pull-db:
	sudo cp -R $(SERVER_DB_PATH)/* ./etc/mysql
	sudo chown $(USER) -R ./etc/mysql

.PHONY: deploy-db
deploy-db:
	sudo cp -R ./etc/mysql/* $(SERVER_DB_PATH)

.PHONY: reload-db
reload-db:
	sudo systemctl restart mysql
