SVGO = require("svgo");
var jsdom = require("jsdom");
var cheerio = require("cheerio");

exports.go = function(req, res) {
	so = new SVGO();
	so.fromString(req.body.svgxml).then(function(min) {
		$ = cheerio.load(min.data);

		res.writeHead(200, {"Content-Type": "text/plain"});
		res.end($.html());
	}).done();
}