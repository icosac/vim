#!/bin/bash
CD=$(pwd)
source "${CD}/../../utils.sh"
echo "Moved in ${CD}"

LIST=(neovim vim tmux zsh) #List of all possible packets to install

#If no package was given in input, ask which to install
if [ "$1" == "" ]; then
  echo "Possible packages for Debian 10 are: ${LIST[*]}"
  read -e -r -p "Insert packages names or \`all\` for to install all packages: " string
  if [ "$string" == "all" ]; then
    packages=("${LIST[*]}")
  else
    packages=("$string")
  fi
else
  for p in "$@"; do
    packages+=("$p")
  done
fi

check_input "${packages[*]}" "${LIST[*]}"
echo "About to install packages: ${packages[*]}"

#Define commands
MK=make
CLONE="git clone"
MOVE=cp
MKDIR="mkdir -p "
echo "Updating system"
if [ "$( whoami )" == "root" ]; then
  apt-get update
  IN="apt-get install -y "
else
  sudo apt-get update
  IN="sudo apt-get install -y "
fi

#Install general packages
$IN curl

#Install packages
#NEOVIM
if in_list "${packages[*]}" "neovim"; then
  echo -e "${BLUE}NEOVIM${NC}"
  echo -e "${GREEN}Intalling neovim from repo$NC"
  $IN neovim
  echo -e "${GREEN}Configuring neovim${NC}"
  echo -e "\tFirst configuring vim"
  if [ ! -d $HOME/.vim ]; then
    $MKDIR $HOME/.vim
  fi
  if [ ! -d $HOME/.config/nvim ]; then
    $MKDIR $HOME/.config/nvim
  fi
  #Move first plugins
  echo -e "if filereadable(expand(\"~/.vim/vimrc.plug\"))\nsource ~/.vim/vimrc.plug\nendif" > $HOME/.vim/vimrc
  MV $MOVE "./vim/vimrc.plug" "$HOME/.vim/vimrc.plug"
  MV $MOVE "./nvim/init.vim" "$HOME/.config/nvim/init.vim"
  curl -fLo $HOME/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  #Install plugin and move correct configuration file
  nvim +PlugInstall +qa
  MV $MOVE "./vim/vimrc" "$HOME/.vim/vimrc"
fi

#VIM
if in_list "${packages[*]}" "vim"; then
  echo -e "${BLUE}VIM${NC}"
  echo -e "${GREEN}Installing vim${NC}"
  $IN vim-gtk python3-pip #silversearcher-ag
  python3 -m pip install --user pynvim
  echo -e "${GREEN}Configuring vim${NC}"
  if [ ! -d $HOME/.vim ]; then
    $MKDIR $HOME/.vim
  fi
  curl -fLo $HOME/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  #Move first plugins to install
  echo -e "if filereadable(expand(\"~/.vim/vimrc.plug\"))\nsource ~/.vim/vimrc.plug\nendif" > $HOME/.vim/vimrc
  MV $MOVE "./vim/vimrc.plug" "$HOME/.vim/vimrc.plug"
  vim +PlugInstall +qa
  #Then move config file
  MV $MOVE "./vim/vimrc" "$HOME/.vim/vimrc"
fi

#TMUX
if in_list "${packages[*]}" "tmux"; then
  echo -e "${BLUE}TMUX${NC}"
  $IN tmux
  echo -e "\tInstalling tmux-mem-cpu-load."
  $CLONE https://github.com/thewtex/tmux-mem-cpu-load
  cd tmux-mem-cpu-load
  $MKDIR build && cd build
  cmake .. && make && sudo make install && echo -e "\tFinished tmux-mem-cpu-load installation, you should probably log out and log back in."
  cd $CD
  rm -rf tmux-mem-cpu-load
  echo -e "${GREEN}Configuring tmux.${NC}"
  MV $MOVE "${PWD}/tmux/tmux.conf" "$HOME/.tmux.conf"
fi

#ZSH -- String with changes to .zshrc
ZSH_RC="
#EXPORTS
export LANG=en_US.UTF-8
if [[ -n \$SSH_CONNECTION ]]; then
  export EDITOR='nvim'
else
  export EDITOR='nvim'
fi

#ALIASES 
alias upgrade_oh_my_zsh=\"omz update\"
"
#OH-MY-ZSH
if in_list "${packages[*]}" "zsh"; then
  ZSH_RC_FILE="${HOME}/.zshrc"
  echo ${ZSH_RC_FILE}

  echo -e "${BLUE}ZSH${NC}"
  echo -e "${GREEN}Installing zsh from repos${NC}"
  $IN zsh
  echo -e "${GREEN}Installing oh-my-zsh${NC}"
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  echo -e "${GREEN}Changing default theme${NC}"
  echo -e "${BLUE}Beginning${NC}"
  sed -i.bak 's/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"bira\"/' ${ZSH_RC_FILE}
  echo -e "${ZSH_RC}" >> ${ZSH_RC_FILE}
  echo -e "${GREEN}Changing shell{$NC}"
fi
