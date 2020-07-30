# Install NVM to manage Node
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
# Use NVM to install latest LTS node version
nvm install --lts

# Install ZSH Shell
apt install zsh -y -q
# Install Oh My ZSH
sh -c "$(wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" -n
# Install autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
# Create default .zshrc config
wget -O /home/$wsuser/.zshrc https://raw.githubusercontent.com/thisisfever/workspace-setup/master/.zshrc
. ~/.zshrc

clear
echo "================================================================="
echo ""
echo "Workspace is ready!"
echo ""
echo "================================================================="
