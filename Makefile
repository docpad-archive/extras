# If you change something here, be sure to change it in package.json's scripts as well

test:
	node ./node_modules/mocha/bin/mocha

install:
	npm install

clean:
	rm -Rf node_modules/ npm-debug.log plugins/*/test/out plugins/*/node_modules plugins/*/npm-debug.log  plugins/*/test/node_modules plugins/*/test/npm-debug.log
	make install

sync:
	git checkout docpad-6.x
	git pull origin docpad-6.x
	git merge master
	git push

	git checkout master
	git pull origin master
	git merge docpad-6.x
	git push

	git checkout docpad-6.x
	git pull origin docpad-6.x
	git merge master
	git push

	git checkout dev
	git pull origin dev
	git merge master
	git push

.PHONY: test install clean sync