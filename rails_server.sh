source $CURRENT/utils.sh

green bin/rails s -b lvh.me -p 4431
add_zshrc "source $WORK_DIR/env/.envrc"
add_zshrc "export MF_DB_SOCKET=/tmp/mysql.sock"
open http://localhost:4431/users/signup
yellow 'assetsを連結しない'
cd $WORK_DIR/forx_web
sed -i '' "s/config.assets.debug = true/config.assets.debug = false/g" config/environments/development.rb
git update-index --skip-worktree config/environments/development.rb
APP_TYPE=10001 bin/rails s -b lvh.me -p 4431