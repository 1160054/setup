export CURRENT=$(cd $(dirname $0);pwd)
mkdir -p $WORK_DIR

function add_zshrc() {
  grep $1 ~/.zshrc || echo $1 >> ~/.zshrc
  eval $1
}
function red() {
  echo -e "\e[31m${@}\e[m"
}
function yellow() {
  echo -e "\e[33m${@}\e[m"
}
function blue() {
  echo -e "\e[34m${@}\e[m"
}
function green() {
  echo -e "\e[32m${@}\e[m"
}