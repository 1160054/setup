#!/bin/zsh

# zsh reset.sh

set -e
WORK_DIR=$HOME/RubymineProjects
START_TIME=`date`
source ~/.zshrc
mkdir -p $WORK_DIR

function add_zshrc() {
  grep $1 ~/.zshrc || echo $1 >> ~/.zshrc
  eval $1
}

echo --------------------------------------------------------------------------------
echo Install homebrew
if ! (brew -v); then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
add_zshrc 'eval "$(/opt/homebrew/bin/brew shellenv)"'
echo --------------------------------------------------------------------------------
echo Install homebrew/cask-versions
if ! (brew tap | grep homebrew/cask-versions); then
  brew tap homebrew/cask-versions
fi
echo --------------------------------------------------------------------------------
echo Install git
if ! (git -v); then
  brew install git
fi
echo --------------------------------------------------------------------------------
echo Install java
if ! (java -version); then
  brew install --cask adoptopenjdk8
fi
add_zshrc 'export JAVA_HOME=`/usr/libexec/java_home -v 1.8`'
echo --------------------------------------------------------------------------------
echo Install mysql
if ! (mysql --version | grep 5.7); then
  brew install mysql@5.7
  brew link mysql@5.7 --force
fi
cp $WORK_DIR/my.cnf ~/.my.cnf
sudo chown -R `whoami`:staff /opt/homebrew/var
if ! (mysql.server status); then
  mysql.server restart
else
  mysql.server reload
fi
echo --------------------------------------------------------------------------------
echo Install nvm
if ! (nvm --version); then
  brew reinstall nvm
fi
add_zshrc 'export NVM_DIR="$HOME/.nvm"'
add_zshrc '\. "/opt/homebrew/opt/nvm/nvm.sh"'
echo --------------------------------------------------------------------------------
echo Install node
if ! (nvm use v16.19.0); then
  nvm install v16.19.0
fi
echo --------------------------------------------------------------------------------
echo Install yarn
if ! (yarn -v | grep 1.22.19); then
  brew install yarn
  yarn policies set-version 1.22.19
fi
echo --------------------------------------------------------------------------------
echo Install libffi
if ! (brew list | grep libffi); then
  brew install libffi
fi
add_zshrc 'export PKG_CONFIG_PATH="/opt/homebrew/opt/libffi/lib/pkgconfig"'
add_zshrc 'export LDFLAGS="-L/opt/homebrew/opt/zlib/lib"'
add_zshrc 'export CPPFLAGS="-I/opt/homebrew/opt/zlib/include"'
echo --------------------------------------------------------------------------------
echo Install rbenv
if ! (rbenv -v); then
  brew install rbenv
fi
add_zshrc 'eval "$(rbenv init - zsh)"'
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/main/bin/rbenv-doctor | bash
echo --------------------------------------------------------------------------------
echo Install ruby 2.6.6
echo forx_schema aggre-db-schema moneybook_api_schema img_mf_schema log_schema
if ! (rbenv versions | grep 2.6.6); then
  cd $WORK_DIR
  rbenv install 2.6.6
fi
rbenv global 2.6.6
if ! (gem list bundler | grep 1.16.1); then
  cd $WORK_DIR
  gem install bundler:1.16.1
fi
echo --------------------------------------------------------------------------------
echo Install ruby 3.1.2
echo forx_web forx_aweb
if ! (rbenv versions | grep 3.1.2); then
  rbenv install 3.1.2
  gem update --system 3.2.3
fi
echo --------------------------------------------------------------------------------
echo Set values in bundle config.
cd $WORK_DIR
bundle config --global build.mysql2 --with-opt-dir="$(brew --prefix openssl)"
bundle config --global build.thin --with-cflags="-Wno-error=implicit-function-declaration"
bundle config --global https://rubygems.pkg.github.com/moneyforward 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
bundle config --global BUNDLE_BUILD__MYSQL2 "--with-ldflags=-L/usr/local/opt/openssl@1.1/lib --with-cppflags=-I/usr/local/opt/openssl@1.1/include"
echo --------------------------------------------------------------------------------
echo Clone the repository
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
)
for repo in $repositories; do
  echo "git clone git@github.com:moneyforward/${repo}.git"
  if [ ! -d $repo ]; then
    git clone git@github.com:moneyforward/${repo}.git  
  fi
done
echo --------------------------------------------------------------------------------
echo source $WORK_DIR/env/.envrc
source $WORK_DIR/env/.envrc
echo --------------------------------------------------------------------------------
echo Drop the database
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
)
for db in $databases; do
  echo "DROP DATABASE IF EXISTS $db; CREATE DATABASE $db;"
  mysql -uroot -e "DROP DATABASE IF EXISTS $db; CREATE DATABASE $db;"
done
echo --------------------------------------------------------------------------------
cd $WORK_DIR/aggre-db-schema && echo `basename $(pwd)`s
gem install bundler --conservative && (bundle check || bundle install) && echo OK
./aggre_asset.sh deploy --host localhost --apply
./aggre_common.sh deploy --host localhost --apply
./aggre_production.sh deploy --host localhost --apply
echo --------------------------------------------------------------------------------
cd $WORK_DIR/moneybook_api_schema && echo `basename $(pwd)`
gem install bundler --conservative && (bundle check || bundle install) && echo OK
bin/rake db:migrate
bin/fast_seed
bin/rake db:migrate RAILS_ENV=test
RAILS_ENV=test bin/fast_seed
echo --------------------------------------------------------------------------------
cd $WORK_DIR/img_mf_schema && echo `basename $(pwd)`
gem install bundler --conservative && (bundle check || bundle install) && echo OK
bin/rake db:migrate RAILS_ENV=development
echo --------------------------------------------------------------------------------
cd $WORK_DIR/forx_web && echo `basename $(pwd)`
gem install bundler --conservative && (bundle check || bundle install) && echo OK
bin/rails db:migrate:primary RAILS_ENV=development
bin/rails db:migrate:primary RAILS_ENV=test
bin/fast_seed all
RAILS_ENV=test bin/fast_seed all
echo --------------------------------------------------------------------------------
cd $WORK_DIR/forx_aweb && echo `basename $(pwd)`
gem install bundler --conservative && (bundle check || bundle install) && echo OK
echo --------------------------------------------------------------------------------
cd $WORK_DIR/forx_schema && echo `basename $(pwd)`
gem install bundler --conservative && (bundle check || bundle install) && echo OK
bin/rake db:structure:load RAILS_ENV=development
bin/rake db:structure:load RAILS_ENV=test
cd db/seed_datas && ../../bin/fast_seed all
RAILS_ENV=test SKIP_HUGE_SEED=1 SKIP_SERVICE_SEED=1 SKIP_INITIAL_SEED_FOR_EX=1 ../../bin/fast_seed all
echo --------------------------------------------------------------------------------
cd $WORK_DIR/log_schema && echo `basename $(pwd)`
gem install bundler --conservative && (bundle check || bundle install) && echo OK
bin/rake db:environment:set RAILS_ENV=development
bin/rake db:structure:load RAILS_ENV=development
echo --------------------------------------------------------------------------------
echo Import aggre_common
mysql -uroot aggre_common < $WORK_DIR/aggre_common.sql
mysql -uroot x_production -e "update for_x_applications set release_status = 'released' where app_type=100057"
echo --------------------------------------------------------------------------------
echo 'assetsを連結しない'
cd $WORK_DIR/forx_web
sed -i '' "s/config.assets.debug = true/config.assets.debug = false/g" config/environments/development.rb
git update-index --skip-worktree config/environments/development.rb
yarn
echo --------------------------------------------------------------------------------
END_TIME=`date`
echo $START_TIME
echo $END_TIME
open http://localhost:4431/users/signup
source ~/RubymineProjects/env/.envrc
add_zshrc "source ~/RubymineProjects/env/.envrc"
add_zshrc "export APP_TYPE=10001"
add_zshrc "export MF_DB_SOCKET=/tmp/mysql.sock"
APP_TYPE=10001 MF_DB_SOCKET=/tmp/mysql.sock bin/rails s -b lvh.me -p 4431

