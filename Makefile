gitlab-build:
	docker build -f gitlab/Dockerfile -t gitlab gitlab/
	
gitlab: gitlab-build
	docker run -it gitlab
