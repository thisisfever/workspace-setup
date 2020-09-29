# Paths
export ZSH="~/.oh-my-zsh"
export COMPOSER_ALLOW_SUPERUSER=1
export PATH=$HOME/.config/composer/vendor/bin:$PATH
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
ZSH_THEME="bira"

# Theme & Plugins
# ZSH_THEME="powerlevel9k/powerlevel9k"
# POWERLEVEL9K_MODE='nerdfont-complete'
# POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs)
# POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=()
# POWERLEVEL9K_SHORTEN_DIR_LENGTH=2

# Example format: plugins=(git zsh-autosuggestions)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-autosuggestions git-auto-fetch ssh-agent)

source $ZSH/oh-my-zsh.sh

# Aliases
alias zshconfig="sudo nano ~/.zshrc"
alias hosts="sudo nano /etc/hosts"
alias zshreload=". ~/.zshrc"
alias nginxreload="sudo systemctl restart nginx"
alias refreshaptkeys="sudo apt-key adv --refresh-keys --keyserver keyserver.ubuntu.com"
alias update="sudo apt update && sudo apt upgrade"
alias pa="php artisan"
alias phpa="php artisan"
alias zipcurrent="sudo zip -r archive.zip ./ -x node_modules/\*"
alias changeowner="sudo chown -R www-data:www-data ."
