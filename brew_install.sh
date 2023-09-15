source $CURRENT/utils.sh
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
green Install java
if ! (java -version); then
  brew install --cask adoptopenjdk8
fi
add_zshrc 'export JAVA_HOME=`/usr/libexec/java_home -v 1.8`'
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
