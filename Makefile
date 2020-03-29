environmet:
	$(shell cp -R $(shell pwd)/secrets/gitlab/*  $(shell pwd)/gitlab/config)

gitlab-build: environmet
	docker build -f gitlab/Dockerfile -t gitlab gitlab/

gitlab: gitlab-build
	docker run -it gitlab bash.

upgrade:
	git reset --hard && git pull && $(MAKE) environmet
