# [DocPad](http://docpad.org) Extras

<!-- BADGES/ -->

<span class="badge-travisci"><a href="http://travis-ci.org/docpad/extras" title="Check this project's build status on TravisCI"><img src="https://img.shields.io/travis/docpad/extras/master.svg" alt="Travis CI Build Status" /></a></span>
<span class="badge-npmversion"><a href="https://npmjs.org/package/docpad-extras" title="View this project on NPM"><img src="https://img.shields.io/npm/v/docpad-extras.svg" alt="NPM version" /></a></span>
<span class="badge-npmdownloads"><a href="https://npmjs.org/package/docpad-extras" title="View this project on NPM"><img src="https://img.shields.io/npm/dm/docpad-extras.svg" alt="NPM downloads" /></a></span>
<span class="badge-daviddm"><a href="https://david-dm.org/docpad/extras" title="View the status of this project's dependencies on DavidDM"><img src="https://img.shields.io/david/docpad/extras.svg" alt="Dependency Status" /></a></span>
<span class="badge-daviddmdev"><a href="https://david-dm.org/docpad/extras#info=devDependencies" title="View the status of this project's development dependencies on DavidDM"><img src="https://img.shields.io/david/dev/docpad/extras.svg" alt="Dev Dependency Status" /></a></span>
<br class="badge-separator" />
<span class="badge-patreon"><a href="https://patreon.com/bevry" title="Donate to this project using Patreon"><img src="https://img.shields.io/badge/patreon-donate-yellow.svg" alt="Patreon donate button" /></a></span>
<span class="badge-opencollective"><a href="https://opencollective.com/bevry" title="Donate to this project using Open Collective"><img src="https://img.shields.io/badge/open%20collective-donate-yellow.svg" alt="Open Collective donate button" /></a></span>
<span class="badge-gratipay"><a href="https://www.gratipay.com/bevry" title="Donate weekly to this project using Gratipay"><img src="https://img.shields.io/badge/gratipay-donate-yellow.svg" alt="Gratipay donate button" /></a></span>
<span class="badge-flattr"><a href="https://flattr.com/profile/balupton" title="Donate to this project using Flattr"><img src="https://img.shields.io/badge/flattr-donate-yellow.svg" alt="Flattr donate button" /></a></span>
<span class="badge-paypal"><a href="https://bevry.me/paypal" title="Donate to this project using Paypal"><img src="https://img.shields.io/badge/paypal-donate-yellow.svg" alt="PayPal donate button" /></a></span>
<span class="badge-bitcoin"><a href="https://bevry.me/bitcoin" title="Donate once-off to this project using Bitcoin"><img src="https://img.shields.io/badge/bitcoin-donate-yellow.svg" alt="Bitcoin donate button" /></a></span>
<span class="badge-wishlist"><a href="https://bevry.me/wishlist" title="Buy an item on our wishlist for us"><img src="https://img.shields.io/badge/wishlist-donate-yellow.svg" alt="Wishlist browse button" /></a></span>
<br class="badge-separator" />
<span class="badge-slackin"><a href="https://slack.bevry.me" title="Join this project's slack community"><img src="https://slack.bevry.me/badge.svg" alt="Slack community badge" /></a></span>

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

<h2>License</h2>

Unless stated otherwise all works are:

<ul><li>Copyright &copy; 2012+ <a href="http://bevry.me">Bevry Pty Ltd</a></li>
<li>Copyright &copy; 2011 <a href="http://balupton.com">Benjamin Lupton</a></li></ul>

and licensed under:

<ul><li><a href="http://spdx.org/licenses/MIT.html">MIT License</a></li></ul>

<!-- /LICENSE -->
