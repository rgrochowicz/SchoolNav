SVGO = require("svgo");
var jsdom = require("jsdom");
var cheerio = require("cheerio");

exports.go = function(req, res) {
	so = new SVGO({coa:{
		disable: "removeUnknownsAndDefaults,convertPathData"
	}});
	so.fromString(req.body.svgxml).then(function(min) {
		$ = cheerio.load(min.data);

		res.render("svgstep2", {svg:$.html()});
	}).done();
}