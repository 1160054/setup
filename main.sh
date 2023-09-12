#!/bin/zsh -e
CURRENT=$(cd $(dirname $0);pwd)
WORK_DIR=$HOME/RubymineProjects
mkdir -p $WORK_DIR
source $CURRENT/utils.sh
source $CURRENT/brew_install.sh
source $CURRENT/rbenv_install.sh
source $CURRENT/git_clone.sh
source $CURRENT/database_reset.sh
source $CURRENT/rails_server.sh
