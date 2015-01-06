# [DocPad](http://docpad.org) Extras

<!-- BADGES/ -->


[![Gittip donate button](http://img.shields.io/gittip/docpad.png)](https://www.gittip.com/docpad/ "Donate weekly to this project using Gittip")
[![Flattr donate button](http://img.shields.io/flattr/donate.png?color=yellow)](http://flattr.com/thing/344188/balupton-on-Flattr "Donate monthly to this project using Flattr")
[![PayPayl donate button](http://img.shields.io/paypal/donate.png?color=yellow)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=QB8GQPZAH84N6 "Donate once-off to this project using Paypal")

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
	cake compile
	npm link
	```

2. Setup this repository

	``` bash
	cd ~
	git clone https://github.com/docpad/extras.git docpad-extras
	cd docpad-extras
	npm link docpad
	npm install
	chmod +x ./app
	```

3. Learn how this application works

	``` bash
	./app --help
	```

4. Clone out all the officially supported plugins and skeletons

	``` bash
	./app clone
	```

5. Run the tests against the cloned out plugins

	``` bash
	./app test
	```

<!-- LICENSE/ -->

## License

Licensed under the incredibly [permissive](http://en.wikipedia.org/wiki/Permissive_free_software_licence) [MIT license](http://creativecommons.org/licenses/MIT/)

Copyright &copy; 2012+ Bevry Pty Ltd <us@bevry.me> (http://bevry.me)
<br/>Copyright &copy; 2011 Benjamin Lupton <b@lupton.cc> (http://balupton.com)

<!-- /LICENSE -->


