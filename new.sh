#!/usr/bin/env bash
clear

echo "Project Name (<project-name>.test)"
read -e projectname

projectname_lower=$(echo "$projectname" | iconv -t ascii//TRANSLIT | sed -r s/[^a-zA-Z0-9]+/-/g | sed -r s/^-+\|-+$//g | tr A-Z a-z)

sudo mkdir ~/projects/$projectname_lower
sudo mkdir ~/projects/$projectname_lower/public_html

echo "Project folder created at ~/projects/$projectname_lower/"
cd ~/projects/$projectname_lower/public_html