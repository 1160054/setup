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
