
/*
 * GET home page.
 */

exports.go = function(req, res){
  res.render('index', { title: 'Express' });
};