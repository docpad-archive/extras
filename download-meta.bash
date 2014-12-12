#!/bin/bash
wget -N https://raw.githubusercontent.com/bevry/base/master/.gitignore
wget -N https://raw.githubusercontent.com/bevry/base/master/.npmignore
wget -N https://raw.githubusercontent.com/bevry/base/master/.travis.yml
wget -N https://raw.githubusercontent.com/bevry/base/master/.editorconfig
wget -N https://raw.githubusercontent.com/bevry/base/master/Cakefile
wget -N https://raw.githubusercontent.com/bevry/base/master/LICENSE.md
wget -N https://raw.githubusercontent.com/bevry/base/master/CONTRIBUTING.md
wget -N https://raw.githubusercontent.com/bevry/base/master/coffeelint.json

git add .gitignore .npmignore .travis.yml .editorconfig Cakefile LICENSE.md CONTRIBUTING.md coffeelint.json

echo "downloaded all files"