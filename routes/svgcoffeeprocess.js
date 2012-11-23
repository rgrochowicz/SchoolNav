cs = require("coffee-script");
fs = require('fs');

exports.go = function(req, res) {
	fs.readFile("public/js/svg.coffee","utf-8",function(e,r) {
		if(e) {
			console.log(e);
		}
		try {
			res.set('Content-Type', 'text/javascript');
			res.end(cs.compile(r));
		} catch(e) {
			res.end(e.message);
		}
	})
}