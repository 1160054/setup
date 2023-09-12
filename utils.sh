function add_zshrc() {
  grep $1 ~/.zshrc || echo $1 >> ~/.zshrc
  eval $1
}
