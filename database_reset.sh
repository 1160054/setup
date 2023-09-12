green source $WORK_DIR/env/.envrc
source $WORK_DIR/env/.envrc
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
)
for db in $databases; do
  blue "DROP DATABASE IF EXISTS $db; CREATE DATABASE $db;"
  mysql -uroot -e "DROP DATABASE IF EXISTS $db; CREATE DATABASE $db;"
done
green --------------------------------------------------------------------------------
cd $WORK_DIR/aggre-db-schema && green `basename $(pwd)`s
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
mysql -uroot aggre_common < aggre_common.sql
mysql -uroot x_production -e "update for_x_applications set release_status = 'released' where app_type=100057"
