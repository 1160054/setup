source $CURRENT/utils.sh
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
)
for repo in $repositories; do
  blue "git clone git@github.com:moneyforward/${repo}.git"
  if [ ! -d $repo ]; then
    git clone git@github.com:moneyforward/${repo}.git
  fi
done
