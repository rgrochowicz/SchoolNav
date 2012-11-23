SVGO = require("svgo");

exports.go = function(req, res) {
	so = new SVGO();
	so.fromFile("public/test.svg").then(function(min) {
		console.log(min);
		res.end(min.data);
	});
}