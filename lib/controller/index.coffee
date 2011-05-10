exports.load=(dir)->
	fs = require 'fs'
	files = fs.readdirSync dir
	for file in files
		if file.match /.coffee$/
			controller = require dir+'/'+file
			for ex of controller
				exports[ex] = controller[ex]