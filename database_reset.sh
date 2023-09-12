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
mysql -uroot aggre_common < aggre_common.sql
mysql -uroot x_production -e "update for_x_applications set release_status = 'released' where app_type=100057"
