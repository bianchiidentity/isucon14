include .env
.PHONY: isucon14 isucon14-bench

ssh: isucon14
bench: isucon14-bench




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
