#!/bin/zsh -e

# export BUNDLE_RUBYGEMS__PKG__GITHUB__COM=ghp_XXXX
# zsh main.sh

export WORK_DIR=~/RubymineProjects
export CURRENT=$(cd $(dirname $0);pwd)
source $CURRENT/utils.sh
source $CURRENT/brew_install.sh
source $CURRENT/rbenv_install.sh
source $CURRENT/c.sh
source $CURRENT/database_reset.sh
source $CURRENT/rails_server.sh
