SVGO = require("svgo");
var jsdom = require("jsdom");
var cheerio = require("cheerio");

exports.go = function(req, res) {
	so = new SVGO();
	so.fromFile("vhs_map_floor1_blank.svg").then(function(min) {
		$ = cheerio.load(min.data);
		idCounter = 0;
		$("#navgroup rect").each(function() {
			var height, points, width, x, y;
			x = parseFloat($(this).attr("x"));
			y = parseFloat($(this).attr("y"));
			width = parseFloat($(this).attr("width"));
			height = parseFloat($(this).attr("height"));
			points = x + "," + y + ":" + (x + width) + "," + y + ":" + (x + width) + "," + (y + height) + ":" + x + "," + (y + height);
			$(this).attr("data-nodes", points).attr("id", "nav_" + (idCounter++));
		});
		/*
		var root = $("svg");
		var pathgroup = $("<g></g>").attr({id:"pathgroup"});
		var navgroup = $("<g></g>").attr({id:"navgroup"});
		var textgroup = $("<g></g>").attr({id:"textgroup"});

		root.append(pathgroup, navgroup, textgroup);
		textgroup.append($("text").remove());
		navgroup.append($("rect[fill='#E0E0E0']").remove());
		pathgroup.append($("line").remove())*/

		res.writeHead(200, {"Content-Type": "image/svg+xml"});
		res.end($.html());
	}).done();
}