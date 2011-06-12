client_script =->
	window.Muse =
		controller: "#CONTROLLER#"
		model: "#MODEL#"
		
		
		
module.exports =(req, res)->
	res.send ";(#{client_script})();"
	