# If you change something here, be sure to change it in package.json's scripts as well

test:
	node ./node_modules/mocha/bin/mocha

install:
	npm install

clean:
	rm -Rf node_modules/ npm-debug.log plugins/*/node_modules plugins/*/npm-debug.log  plugins/*/test/node_modules plugins/*/test/npm-debug.log
	make install

.PHONY: test install clean