# If you change something here, be sure to change it in package.json's scripts as well

test:
	npm test

install:
	npm install

clean:
	rm -Rf node_modules/ npm-debug.log plugins/*/test/out plugins/*/node_modules plugins/*/npm-debug.log  plugins/*/test/node_modules plugins/*/test/npm-debug.log
	make install
	npm link docpad

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

.PHONY: test install clean sync