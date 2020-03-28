FROM ubuntu:19.10 as base 
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && apt-get upgrade -y && apt-get install -y vim
RUN update-alternatives --set editor /usr/bin/vim.basic
RUN apt-get install -y build-essential zlib1g-dev libyaml-dev libssl-dev libgdbm-dev libre2-dev \
libreadline-dev libncurses5-dev libffi-dev curl openssh-server checkinstall libxml2-dev \
libxslt-dev libcurl4-openssl-dev libicu-dev logrotate rsync python-docutils pkg-config cmake \
runit postgresql-client libpq-dev

RUN apt-get install -y libkrb5-dev
RUN apt-get remove git-core
RUN apt-get install -y libcurl4-openssl-dev libexpat1-dev gettext libz-dev libssl-dev build-essential

RUN curl --silent --show-error --location https://ftp.pcre.org/pub/pcre/pcre2-10.33.tar.gz --output pcre2.tar.gz && \
tar -xzf pcre2.tar.gz && \
cd pcre2-10.33 && \
chmod +x configure && \
./configure --prefix=/usr --enable-jit && \
make && \
make install

RUN cd /tmp && \
curl --remote-name --location https://www.kernel.org/pub/software/scm/git/git-2.24.1.tar.gz && \
echo 'ad5334956301c86841eb1e5b1bb20884a6bad89a10a6762c958220c7cf64da02  git-2.24.1.tar.gz' | shasum -a256 -c - && tar -xzf git-2.24.1.tar.gz && \
cd git-2.24.1/ && \
./configure --with-libpcre && \
make prefix=/usr/local all && make prefix=/usr/local install

RUN apt-get install -y graphicsmagick
RUN apt-get install -y postfix

# == Ruby
RUN apt-get remove ruby1.8

RUN mkdir /tmp/ruby && cd /tmp/ruby && \
curl --remote-name https://cache.ruby-lang.org/pub/ruby/2.6/ruby-2.6.5.tar.gz && \
echo '1416ce288fb8bfeae07a12b608540318c9cace71  ruby-2.6.5.tar.gz' | shasum -c - && tar xzf ruby-2.6.5.tar.gz && \
cd ruby-2.6.5 && \
./configure --disable-install-rdoc && make && make install

RUN gem install bundler --no-document --version '< 2'

# == Go
RUN rm -rf /usr/local/go
RUN curl --remote-name https://dl.google.com/go/go1.13.5.linux-amd64.tar.gz && \
echo '512103d7ad296467814a6e3f635631bd35574cab3369a97a323c9a585ccaa569  go1.13.5.linux-amd64.tar.gz' | shasum -a256 -c - && \
tar -C /usr/local -xzf go1.13.5.linux-amd64.tar.gz && \
ln -sf /usr/local/go/bin/{go,godoc,gofmt} /usr/local/bin/ && \
rm go1.13.5.linux-amd64.tar.gz

# == Node
RUN curl --location https://deb.nodesource.com/setup_12.x | bash - && \
apt-get install -y nodejs && curl --silent --show-error https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
apt-get update && apt-get install yarn

# == Gitlab
RUN adduser --disabled-login --gecos 'GitLab' --home /opt/git git
USER git 
RUN git clone https://gitlab.com/gitlab-org/gitlab-foss.git -b 12-9-stable /opt/git/gitlab

WORKDIR /opt/git/gitlab

COPY config/ config/
USER root
# Установка прав
RUN chmod 0600 config/secrets.yml && chown -R git log/ && chown -R git tmp/ && \
chmod -R u+rwX,go-w log/ && chmod -R u+rwX tmp/ && chmod -R u+rwX tmp/pids/ && \
chmod -R u+rwX tmp/sockets/ && mkdir -p public/uploads/ && chmod 0700 public/uploads && \
chmod -R u+rwX builds/ && chmod -R u+rwX shared/artifacts/ && chmod -R ug+rwX shared/pages/ && \
chmod o-rwx config/database.yml

# Настройка git
RUN git config --global core.autocrlf input && \
git config --global gc.auto 0 && \
git config --global repack.writeBitmaps true && \
git config --global receive.advertisePushOptions true && \
git config --global core.fsyncObjectFiles true

# Gems
RUN bundle install --deployment --without development test mysql aws kerberos

# GitLab Shell
RUN bundle exec rake gitlab:shell:install REDIS_URL=http://redis RAILS_ENV=production SKIP_STORAGE_VALIDATION=true

# Workhorse
RUN bundle exec rake "gitlab:workhorse:install[/opt/git/gitlab-workhorse]" RAILS_ENV=production

# Elasticsearch-indexer
RUN bundle exec rake "gitlab:indexer:install[/opt/git/gitlab-elasticsearch-indexer]" RAILS_ENV=production

# Pages
RUN git clone https://gitlab.com/gitlab-org/gitlab-pages.git /opt/git/gitlab-pages
WORKDIR /opt/git/gitlab-pages
RUN git checkout v$(</opt/git/gitlab/GITLAB_PAGES_VERSION) && make

# Gitaly
WORKDIR /opt/git/gitlab/
RUN bundle exec rake "gitlab:gitaly:install[/opt/git/gitaly,/opt/git/repositories]" RAILS_ENV=production
RUN chmod 0700 /opt/git/gitlab/tmp/sockets/private
RUN chown git /opt/git/gitlab/tmp/sockets/private

# Поправить конфига