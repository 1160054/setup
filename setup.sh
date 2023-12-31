#!/bin/zsh -e
# Usage
#
# echo "source `pwd`/setup.sh" >> ~/.zshrc
#
# reset_all
#
# brew_install
# rbenv_install
# git_clone
# database_reset
# database_import
#
# local_forx_web
# local_forx_aweb
# local_evora
# local_camaro

# デフォルトの作業ディレクトリ
[ -z "$WORK_DIR" ] && WORK_DIR=~/RubymineProjects
mkdir -p $WORK_DIR

function reset_all() {
    brew_install
    rbenv_install
    git_clone
    database_reset
}
function brew_install(){
  green Install homebrew
  if ! (brew -v); then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  add_zshrc 'eval "$(/opt/homebrew/bin/brew shellenv)"'
  green chmod -R $(whoami) /opt/homebrew
  if ! (ls -l /opt | grep homebrew | grep `whoami`); then
    sudo chown -R $(whoami) /opt/homebrew
  fi
  green Install homebrew/cask-versions
  if ! (brew tap | grep homebrew/cask-versions); then
    brew tap homebrew/cask-versions
  fi
  green Install git
  if ! (git -v); then
    brew install git
  fi
  green Install java 8
  if ! (ls /Library/Java/JavaVirtualMachines/adoptopenjdk-8.jdk/Contents/Home/bin/java); then
    brew install --cask adoptopenjdk8
  fi
  green Install java amazon-corretto-11
  if ! (ls /Library/Java/JavaVirtualMachines/amazon-corretto-11.jdk/Contents/Home/bin/java); then
    curl -L https://corretto.aws/downloads/latest/amazon-corretto-11-x64-macos-jdk.tar.gz -o amazon-corretto-11-jdk.tar.gz
    tar -xzf amazon-corretto-11-jdk.tar.gz -C /Library/Java/JavaVirtualMachines/amazon-corretto-11.jdk --strip-components=1
    sudo mkdir -p /Library/Java/JavaVirtualMachines/amazon-corretto-11.jdk/
    sudo tar -xvf amazon-corretto-11-jdk.tar.gz -C /Library/Java/JavaVirtualMachines/amazon-corretto-11.jdk --strip-components=1
    rm amazon-corretto-11-jdk.tar.gz
  fi
  green Install mysql
  if ! (mysql --version | grep 5.7); then
    brew install mysql@5.7
    brew link mysql@5.7 --force
  fi
  cp ./my.cnf ~/.my.cnf
  if ! (mysql.server status); then
    mysql.server restart
  else
    mysql.server reload
  fi
  green Install nvm
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
  if ! (nvm --version); then
    brew reinstall nvm
  fi
  add_zshrc 'export NVM_DIR="$HOME/.nvm"'
  add_zshrc '\. "/opt/homebrew/opt/nvm/nvm.sh"'
  green Install node
  if ! (nvm use v16.19.0); then
    nvm install v16.19.0
  fi
  green Install yarn
  if ! (yarn -v | grep 1.22.19); then
    brew install yarn
    yarn policies set-version 1.22.19
  fi
  green Install gnu-getopt
  if ! (getopt); then
    brew install gnu-getopt
  fi
}
function rbenv_install() {
  green Install libffi # rubyのインストールに必要
  if ! (brew list | grep libffi); then
    brew install libffi
  fi
  if ! (brew list | grep zlib); then
    brew install zlib # rubyのインストールに必要
  fi
  add_zshrc 'export PKG_CONFIG_PATH="/opt/homebrew/opt/libffi/lib/pkgconfig"'
  add_zshrc 'export LDFLAGS="-L/opt/homebrew/opt/zlib/lib"'
  add_zshrc 'export CPPFLAGS="-I/opt/homebrew/opt/zlib/include"'
  green Install rbenv
  if ! (rbenv -v); then
    brew install rbenv
  fi
  add_zshrc 'eval "$(rbenv init - zsh)"'
  curl -fsSL https://github.com/rbenv/rbenv-installer/raw/main/bin/rbenv-doctor | bash
  green Install ruby 2.6.6
  blue forx_schema aggre-db-schema moneybook_api_schema img_mf_schema log_schema
  if ! (rbenv versions | grep 2.6.6); then
    cd $WORK_DIR
    rbenv install 2.6.6
  fi
  rbenv global 2.6.6
  if ! (gem list bundler | grep 1.16.1); then
    cd $WORK_DIR
    gem install bundler:1.16.1
  fi
  green Install ruby 3.1.2
  blue forx_web forx_aweb
  if ! (rbenv versions | grep 3.1.2); then
    rbenv install 3.1.2
    gem update --system 3.2.3
  fi
  green Set values in bundle config.
  cd $WORK_DIR
  bundle config --global build.mysql2 --with-opt-dir="$(brew --prefix openssl)"
  bundle config --global build.thin --with-cflags="-Wno-error=implicit-function-declaration"
  bundle config --global https://rubygems.pkg.github.com/moneyforward $BUNDLE_RUBYGEMS__PKG__GITHUB__COM
  bundle config --global BUNDLE_BUILD__MYSQL2 "--with-ldflags=-L/usr/local/opt/openssl@1.1/lib --with-cppflags=-I/usr/local/opt/openssl@1.1/include"
}
function git_clone() {
  green Clone the repository
  cd $WORK_DIR
  repositories=(
    forx_web
    forx_aweb
    forx_schema
    aggre-db-schema
    moneybook_api_schema
    img_mf_schema
    log_schema
    env
    camaro
    evora
  )
  for repo in $repositories; do
    blue "git clone git@github.com:moneyforward/${repo}.git"
    if [ ! -d $repo ]; then
      git clone git@github.com:moneyforward/${repo}.git
    fi
  done
}
function database_reset() {
  green Drop the database
  databases=(
    aggre_asset
    aggre_common
    aggre_production
    x_production
    x_test
    img_mf_production
    log_production
    img_mf_test
    log_test
    x_pfm_production
    moneybook_api_production
    x_pfm_test
    moneybook_api_test
    evora
  )
  for db in $databases; do
    blue "DROP DATABASE IF EXISTS $db; CREATE DATABASE $db;"
    mysql -uroot -e "DROP DATABASE IF EXISTS $db; CREATE DATABASE $db;"
  done
  source $WORK_DIR/env/.envrc
  green --------------------------------------------------------------------------------
  cd $WORK_DIR/aggre-db-schema && green `basename $(pwd)`
  gem install bundler --conservative && (bundle check || bundle install) && green OK
  ./aggre_asset.sh deploy --host localhost --apply
  ./aggre_common.sh deploy --host localhost --apply
  ./aggre_production.sh deploy --host localhost --apply
  green --------------------------------------------------------------------------------
  cd $WORK_DIR/moneybook_api_schema && green `basename $(pwd)`
  gem install bundler --conservative && (bundle check || bundle install) && green OK
  bin/rake db:migrate
  bin/fast_seed
  bin/rake db:migrate RAILS_ENV=test
  RAILS_ENV=test bin/fast_seed
  green --------------------------------------------------------------------------------
  cd $WORK_DIR/img_mf_schema && green `basename $(pwd)`
  gem install bundler --conservative && (bundle check || bundle install) && green OK
  bin/rake db:migrate RAILS_ENV=development
  green --------------------------------------------------------------------------------
  cd $WORK_DIR/forx_web && green `basename $(pwd)`
  gem install bundler --conservative && (bundle check || bundle install) && green OK
  bin/rails db:migrate:primary RAILS_ENV=development
  bin/rails db:migrate:primary RAILS_ENV=test
  bin/fast_seed all
  RAILS_ENV=test bin/fast_seed all
  green --------------------------------------------------------------------------------
  cd $WORK_DIR/forx_aweb && green `basename $(pwd)`
  gem install bundler --conservative && (bundle check || bundle install) && green OK
  green --------------------------------------------------------------------------------
  cd $WORK_DIR/forx_schema && green `basename $(pwd)`
  gem install bundler --conservative && (bundle check || bundle install) && green OK
  bin/rake db:structure:load RAILS_ENV=development
  bin/rake db:structure:load RAILS_ENV=test
  cd db/seed_datas && ../../bin/fast_seed all
  RAILS_ENV=test SKIP_HUGE_SEED=1 SKIP_SERVICE_SEED=1 SKIP_INITIAL_SEED_FOR_EX=1 ../../bin/fast_seed all
  green --------------------------------------------------------------------------------
  cd $WORK_DIR/log_schema && green `basename $(pwd)`
  gem install bundler --conservative && (bundle check || bundle install) && green OK
  bin/rake db:environment:set RAILS_ENV=development
  bin/rake db:structure:load RAILS_ENV=development
  green --------------------------------------------------------------------------------
  green Import aggre_common
  mysql -uroot aggre_common < $WORK_DIR/setup/aggre_common.sql
  mysql -uroot x_production -e "update for_x_applications set release_status = 'released' where app_type=10057"
  green --------------------------------------------------------------------------------
  mysqldump -uroot --all-databases > $WORK_DIR/all-databases.sql
}
function database_import() {
   mysql -uroot < $WORK_DIR/all-databases.sql
}
function add_zshrc() {
  grep $1 ~/.zshrc || echo $1 >> ~/.zshrc
  eval $1
}
function red() {
  echo -e "\e[31m${@}\e[m"
}
function yellow() {
  echo -e "\e[33m${@}\e[m"
}
function blue() {
  echo -e "\e[34m${@}\e[m"
}
function green() {
  echo -e "\e[32m${@}\e[m"
}
function local_forx_web() {
  cd $WORK_DIR/forx_web
  source $WORK_DIR/env/.envrc
  APP_TYPE=10001
  green MF_DB_SOCKET=/tmp/mysql.sock APP_TYPE=$APP_TYPE bin/rails s -b lvh.me -p 4431
  MF_DB_SOCKET=/tmp/mysql.sock APP_TYPE=$APP_TYPE bin/rails s -b lvh.me -p 4431
}
function local_forx_aweb(){
  cd $WORK_DIR/forx_aweb
  source $WORK_DIR/env/.envrc
  green bundle exec rails s -b lvh.me -p 3443
  MF_DB_SOCKET=/tmp/mysql.sock bundle exec rails s -b lvh.me -p 3443
}
function local_evora() {
  cd $WORK_DIR/evora
  green ./gradlew clean appRun --console=plain
  JAVA_HOME=`/usr/libexec/java_home -v 1.8` ./gradlew clean appRun --console=plain
}
function local_camaro() {
    cd $WORK_DIR/camaro
    CAMARO_DB_HOST_PORT=3309 docker-compose up -d
    CAMARO_DB_HOST_PORT=3309 JAVA_HOME=`/usr/libexec/java_home -v 11` ./gradlew clean bootRun
}
function local_hermes() {
  cd $WORK_DIR/hermes
  make docker/run-local
}