# [DocPad](http://docpad.org) Extras

<!-- BADGES/ -->

[![Dependency Status](https://img.shields.io/david/docpad/extras.svg)](https://david-dm.org/docpad/extras)
[![Dev Dependency Status](https://img.shields.io/david/dev/docpad/extras.svg)](https://david-dm.org/docpad/extras#info=devDependencies)<br/>
[![Gratipay donate button](https://img.shields.io/gratipay/docpad.svg)](https://www.gratipay.com/docpad/ "Donate weekly to this project using Gratipay")
[![Flattr donate button](https://img.shields.io/badge/flattr-donate-yellow.svg)](http://flattr.com/thing/344188/balupton-on-Flattr "Donate monthly to this project using Flattr")
[![PayPayl donate button](https://img.shields.io/badge/paypal-donate-yellow.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=QB8GQPZAH84N6 "Donate once-off to this project using Paypal")
[![BitCoin donate button](https://img.shields.io/badge/bitcoin-donate-yellow.svg)](https://coinbase.com/checkouts/9ef59f5479eec1d97d63382c9ebcb93a "Donate once-off to this project using BitCoin")
[![Wishlist browse button](https://img.shields.io/badge/wishlist-donate-yellow.svg)](http://amzn.com/w/2F8TXKSNAFG4V "Buy an item on our wishlist for us")

<!-- /BADGES -->


A test runner for all of DocPad's officially supported extensions


## FAQ

### How do I add a skeleton?

Send a pull request for [this file](https://github.com/docpad/extras/blob/docpad-6.x/exchange.json)

### A skeleton is out of date or broken, what should I do?

Add `(out of date)` to the name of the out of date skeleton in [this file](https://github.com/docpad/extras/blob/docpad-6.x/exchange.json) by clicking edit and sending a pull request.


## Usage Instructions for the Extras Team

1. Setup a development copy of DocPad

	``` bash
	cd ~
	git clone https://github.com/bevry/docpad.git
	cd docpad
	npm run prepare
	npm link
	```

2. Setup this repository

	``` bash
	cd ~
	git clone https://github.com/docpad/extras.git docpad-extras
	cd docpad-extras
	git checkout docpad-6.x
	npm link docpad
	npm install
	```

3. Learn how this application works

	``` bash
	npm run info
	```

4. Clone out all the officially supported plugins and skeletons

	``` bash
	npm run clone
	```

5. Run the tests against the cloned out plugins

	``` bash
	npm test
	```

<!-- LICENSE/ -->

## License

Unless stated otherwise all works are:

- Copyright &copy; 2012+ Bevry Pty Ltd <us@bevry.me> (http://bevry.me)
- Copyright &copy; 2011 Benjamin Lupton <b@lupton.cc> (http://balupton.com)

and licensed under:

- The incredibly [permissive](http://en.wikipedia.org/wiki/Permissive_free_software_licence) [MIT License](http://opensource.org/licenses/mit-license.php)

<!-- /LICENSE -->
