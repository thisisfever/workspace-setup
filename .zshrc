# Paths
export ZSH="~/.oh-my-zsh"
export COMPOSER_ALLOW_SUPERUSER=1
export PATH=$HOME/.config/composer/vendor/bin:$PATH
ZSH_THEME="bira"
# ZSH_THEME="gianu"
# ZSH_THEME="powerlevel9k/powerlevel9k"
# POWERLEVEL9K_MODE='nerdfont-complete'
# POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs)
# POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=()
# POWERLEVEL9K_SHORTEN_DIR_LENGTH=2

# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-autosuggestions git-auto-fetch ssh-agent)

source $ZSH/oh-my-zsh.sh

# Aliases
alias zshconfig="nano ~/.zshrc"
alias hosts="sudo nano /etc/hosts"
alias zshreload=". ~/.zshrc"
alias nginxreload="sudo systemctl restart nginx"
alias update="sudo apt update && sudo apt upgrade"
alias pa="php artisan"
alias phpa="php artisan"
alias zipcurrent="zip -r archive.zip ./ -x node_modules/\*"
alias changeowner="sudo chown -R www-data:www-data ~/projects/"
