
exports.setup = function(app) {

	app.get("/", require("./routes/index").go);
	app.get("/svg", require("./routes/svg").go);
	app.get("/svgstep1", require("./routes/svgstep1").go);
	app.post("/svgstep2", require("./routes/svgstep2").go);
	app.get("/svg.js", require("./routes/svgcoffeeprocess").go);
	app.get("/processed.svg", require("./routes/processed").go);
	app.get("/processsvg.js", require("./routes/processsvg").go);


}