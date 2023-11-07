export PROMPT="%~ > "
export EDITOR=emacs
export APP="/Users/onodera.yudai.c0704/RubymineProjects/forx_web"
export BUNDLE_RUBYGEMS__PKG__GITHUB__COM=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
export JAVA_HOME=`/usr/libexec/java_home -v 1.8`
export NVM_DIR="$HOME/.nvm"
export PKG_CONFIG_PATH="/opt/homebrew/opt/libffi/lib/pkgconfig"
export LDFLAGS="-L/opt/homebrew/opt/zlib/lib"
export CPPFLAGS="-I/opt/homebrew/opt/zlib/include"
export APP_TYPE=10001
export MF_DB_SOCKET=/tmp/mysql.sock
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY="YES"
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
export HERMES_HOST_URL=http://localhost:8083
export PATH="$GOROOT/bin:$PATH"
export PATH="$PATH:$GOPATH/bin"

alias z='source ~/.zshrc; source ~/.zprofile'
alias a="clear; cd $APP; git log --oneline -n 5; git status; git branch; ignore"
alias s="grep -r --color --binary-files=without-match --exclude={'*.min.js','*jquery*'} --exclude-dir={log,.git,tmp,node_modules,public,.yarn,mfx_api_docs} $1"

eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(rbenv init - zsh)"
eval "$(goenv init -)"

source ~/RubymineProjects/setup/setup.sh
source ~/RubymineProjects/env/.envrc
source ~/RubymineProjects/hermes/.envrc
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

function stg1(){
  ssh money-book@stg1-jenkins01.ebisubook.com -oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedAlgorithms=+ssh-rsa -tt "ssh stg1-forxapp11in"
}
function stg2(){
  ssh money-book@stg1-jenkins01.ebisubook.com -oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedAlgorithms=+ssh-rsa -tt "ssh stg1-forxapp12in"
}

function stg1-tail() {
    ssh -tt stg ssh -tt stg1-forxapp11in tail -F /mbook/log/rails/forx_web.log
}

function stg2-tail() {
    ssh -tt stg ssh -tt stg1-forxapp12in tail -F /mbook/log/rails/forx_web.log
}

function pod(){
    kubectl get pods -l app.kubernetes.io/name=forx-web -n mfx-retail-d
}

function kube() {
    if ! (aws sts get-caller-identity --profile idev); then
    	aws sso login --profile idev
    fi
    if ! (aws configure list-profiles | grep idev); then
    	aws configure sso --profile idev
    fi
    aws --profile idev eks --region ap-northeast-1 update-kubeconfig --name idev
    kubectl ns mfx-retail-d
    kubectl exec xdb-0 --namespace shared-db -- env > /tmp/.env.idev
    #telepresence connect
}

function rr() {
    START_TIME=`date`
    databases=(aggre_asset   aggre_common aggre_production
	       x_production      x_test
	       img_mf_production log_production
	       img_mf_test       log_test
	       x_pfm_production  moneybook_api_production
	       x_pfm_test        moneybook_api_test)
    for db in $databases; do
        echo "DROP DATABASE IF EXISTS $db; CREATE DATABASE $db;"
        mysql -uroot -e "DROP DATABASE IF EXISTS $db; CREATE DATABASE $db;"
    done
    echo $START_TIME && \
	source ~/RubymineProjects/env/.envrc && \
	cd ~/RubymineProjects/aggre-db-schema && \
	system ./aggre_asset.sh deploy --host localhost --apply && \
	system ./aggre_common.sh deploy --host localhost --apply && \
	system ./aggre_production.sh deploy --host localhost --apply && \
	cd ~/RubymineProjects/moneybook_api_schema && \
	system bin/rake db:migrate RAILS_ENV=development && \
	system bin/fast_seed && \
	system bin/rake db:migrate RAILS_ENV=test && \
	system RAILS_ENV=test bin/fast_seed && \
	cd ~/RubymineProjects/img_mf_schema && \
	system rbenv local 2.6.6 && rbenv install -s && \
	system bin/rake db:migrate RAILS_ENV=development && \
	cd ~/RubymineProjects/forx_web && \
	system bin/rails db:migrate:primary RAILS_ENV=development && \
	system bin/rails db:migrate:primary RAILS_ENV=test
	system bin/fast_seed all && \
	system RAILS_ENV=test bin/fast_seed all && \
	cd ~/RubymineProjects/forx_schema && \
	system bin/rake db:structure:load RAILS_ENV=development && \
	system bin/rake db:structure:load RAILS_ENV=test && \
	system cd db/seed_datas && ../../bin/fast_seed all && \
	system RAILS_ENV=test SKIP_HUGE_SEED=1 SKIP_SERVICE_SEED=1 SKIP_INITIAL_SEED_FOR_EX=1 ../../bin/fast_seed all && \
	cd ~/RubymineProjects/log_schema && \
	system bin/rake db:structure:load RAILS_ENV=development && \
	mysql -uroot aggre_common < /Users/onodera.yudai.c0704/RubymineProjects/setup/aggre_common.sql && \
	mysql -uroot x_production -e "update for_x_applications set release_status = 'released' where app_type=10057"
	END_TIME=`date`
	echo $START_TIME
	echo $END_TIME
	#open http://localhost:4431/users/signup
	mysqldump -uroot --all-databases > ~/RubymineProjects/all-databases.sql
}

function system() {
    green [ `basename \`pwd\`` ] "$@"
    eval "$@"
}

function active(){
    i=0
    while do
	if [[ $((i%60)) -eq 0 ]]; then
	    cliclick kd:fn kp:keys-light-down
	fi
	i=$((i+1))
	line=`date`
	printf '\r%*s\r' ${lenLine:-${#line}}
        printf "%s" "$line"
	sleep 1
    done
}

function web() {
    ssh -i ~/.ssh/pdev money-book@forxweb-centos7-test-w9frgvr.pdev.ebisubook.com
}

function aweb() {
    ssh -i ~/.ssh/pdev money-book@forxaweb-centos7-test-w9frgvr.pdev.ebisubook.com
}

function web-tail (){
    ssh web "tail -f /mbook/log/**/*.log"
}

function aweb-tail(){
     ssh aweb "tail -f /mbook/log/**/*.log"
}

function idev-tags() {
  for NAME in forx-web forx-aweb mfx-pfm-api acty camaro mfx-push
  do
    newTag=`aws ecr describe-images --profile idev --repository-name ${NAME} --query "imageDetails[?(contains(to_string(imageTags), 'release-') || contains(to_string(imageTags), 'master-'))][imagePushedAt, imageTags[0]]" --output text | sort -r | awk '{print $2}' | head -n 1`
    echo "- name: 361775621992.dkr.ecr.ap-northeast-1.amazonaws.com/$NAME"
    echo "  newName: 361775621992.dkr.ecr.ap-northeast-1.amazonaws.com/${NAME}"
    echo "  newTag: ${newTag}"
  done
}

function ignore-list() {
  echo services/camaro/base/kustomization.yaml config/environments/development.rb yarn.lock package.json before after
}

function ignore() {
  for FILE in `ignore-list`
  do
    if [ -f $FILE ]; then
      git update-index --skip-worktree $FILE
    fi
  done
  git ls-files -v | grep -v H
}
function unignore() {
  for FILE in `ignore-list`
  do
    if [ -f $FILE ]; then
      git update-index --no-skip-worktree $FILE
    fi
  done
  git ls-files -v | grep -v H
}
