
exports.setup = function(app) {

	app.get("/", require("./routes/index").go);
	app.get("/svg", require("./routes/svg").go);
	app.get("/svg.js", require("./routes/svgcoffeeprocess").go);
	app.get("/processed.svg", require("./routes/processed").go)


}