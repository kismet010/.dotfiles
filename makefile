#  System maintenance
#  kismet010 / Antonio Cañas
################################################################################

SHELL := /bin/bash

# Add/remove as needed
SERVER_FILES = aliases tmux.conf vimrc 
DEVELOPMENT_FILES = vim vimrc.local zshrc sshrc sshrc.d

# Paths
BIN = ~/bin
SRC = ~/src
WWW = ~/www

USER = $(shell id -u)
ifneq ($USER, 0)  # 'sudo' for non root users
	SUDO = sudo
endif

define install
	$(SUDO) apt-get -y --force-yes install --no-install-recommends $1
endef

define symlink
	@PWD=$$(pwd)
	@for FILE in $$PWD/$1/* ; do \
		FILE=$$(basename "$$FILE") ; \
		echo "Symlinking: $$FILE" ; \
		rm -rf ~/.$$FILE ; \
		ln -s $$PWD/$1/$$FILE ~/.$$FILE ; \
	done
endef
	
# Colors 
define info 
	@tput setaf 6; echo "###$1"; tput sgr0
endef
define success 
	@tput setaf 2; echo "###$1"; tput sgr0
endef
define warning
	@tput setaf 2; echo "###$1"; tput sgr0
endef

# Silent make unless told not to
ifneq ($(strip $(SILENT)),no)
.SILENT:
endif


################################################################################
# Targets 
################################################################################

all:
	$(call info, "Press number:")
	@echo "1) Update system";
	@echo "2) Install all";
	@echo "3) Minimal config";
	@echo "4) Development tools";
	@echo "5) GUI & Desktop";
	@read n ; \
	case $$n in \
	    1) $(MAKE) update ;; \
	    2) $(MAKE) install-all ;; \
	    3) $(MAKE) minimal ;; \
	    4) $(MAKE) development ;; \
	    5) $(MAKE) gui ;; \
	    *) tput setaf 3; echo "Invalid option"; tput sgr0; exit ;; \
	esac

clean:
	$(call info, "Cleaning /home")
	@find ! -name '.|.dotfiles' -maxdepth 1 -delete
	@mkdir -p $(BIN) $(SRC) $(WWW)

update:
	@sudo apt-get upgrade ; sudo apt-get update ; apt-get autoremove
	@git add . ; git commit -m "update" ; git pull ; git push
	$(call info, "Updating...")
	$(call symlink,shell)
	$(call symlink,dev)
	$(call symlink,gui)

install-all:
	@$(MAKE) -j minimal development
	@$(MAKE) desktop 
	
minimal:
	$(call symlink,shell)

development:
	$(call info, "Installing development tools")
	@$(call install, zsh tmux vim-nox)
	@$(MAKE) zshrc
	@$(MAKE) tmux 
	@$(MAKE) vimrc
	@$(MAKE) sshrc
	$(call symlink,dev)
	@$(SHELL "sudo chsh -s $(which zsh)"

desktop:
	$(call info, "Installing GUI")
	@$(call install, rxvt-unicode-256color fonts-inconsolata)
	$(call symlink,gui)

zshrc: 
	$(call info, "Configuring Zsh")
	@git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh

tmux:
	$(call info, "Configuring Tmux")
	@git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

vimrc:
	$(call info, "Configuring Vim")
	@git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle
	@vim +BundleInstall +qall

sshrc:
	$(call info, "Installing sshrc")
	@wget https://raw.githubusercontent.com/Russell91/sshrc/master/sshrc
	@chmod +x $@ 
	@mv $@ $(BIN)

server:
	@$(call install, ca-certificates build-essential)
	@$(MAKE) lamp

lamp:
	$(call info, "Installing lamp")
	$(call install, apache2 mysql-server php5-mysql php5-cli php5-mcrypt phpmyadmin)
	$(call warning, "Add 'Include /etc/phpmyadmin/apache.conf' to /etc/apache2/apache2.conf")
	@$(SUDO) service apache2 restart

nodejs:
	$(call info, "Installing Node.js")
	$(call install, npm nodejs)
	@$(SUDO) ln -s /usr/bin/nodejs /usr/bin/node
