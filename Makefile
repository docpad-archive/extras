# If you change something here, be sure to change it in package.json's scripts as well

clean:
	rm -Rf node_modules/ npm-debug.log plugins/*/test/out plugins/*/node_modules plugins/*/npm-debug.log  plugins/*/test/node_modules plugins/*/test/npm-debug.log
	make install
	npm link docpad

clone:
	coffee ./runner.coffee --clone=yes

install:
	npm install

sync:
	git checkout docpad-6.x
	git pull origin docpad-6.x
	git merge master

	git checkout master
	git pull origin master
	git merge docpad-6.x

	git checkout docpad-6.x
	git merge master

	git checkout dev
	git pull origin dev
	git merge master

	git checkout master
	git push

test:
	coffee ./runner.coffee --test=yes --joe-reporter=list --skip=pygments,highlightjs

.PHONY: clean clone install sync test