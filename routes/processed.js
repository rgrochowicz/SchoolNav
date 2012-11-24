SVGO = require("svgo");
var jsdom = require("jsdom");
var cheerio = require("cheerio");

exports.go = function(req, res) {
	so = new SVGO();
	so.fromFile("public/test.svg").then(function(min) {
		$ = cheerio.load(min.data);
		var root = $("svg");
		$("path[fill='none'],rect[fill='none']").remove();
		var pathgroup = $("<g></g>").attr({id:"pathgroup"});
		var navgroup = $("<g></g>").attr({id:"navgroup"});
		var textgroup = $("<g></g>").attr({id:"textgroup"});

		root.append(pathgroup, navgroup, textgroup);
		textgroup.append($("text").remove());

		res.writeHead(200, {"Content-Type": "image/svg+xml"});
		res.end($.html());
	}).done();
}