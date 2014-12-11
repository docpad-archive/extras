#!/bin/bash
rm .gitignore; wget https://raw.github.com/bevry/base/master/.gitignore
rm .npmignore; wget https://raw.github.com/bevry/base/master/.npmignore
rm .travis.yml; wget https://raw.github.com/bevry/base/master/.travis.yml
rm Cakefile; wget https://raw.github.com/bevry/base/master/Cakefile
rm LICENSE.md; wget https://raw.github.com/bevry/base/master/LICENSE.md
rm CONTRIBUTING.md; wget https://raw.github.com/bevry/base/master/CONTRIBUTING.md
echo "downloaded all files"