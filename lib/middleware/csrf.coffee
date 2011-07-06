exempt = []

exports.token = (req, res)->
	req.session.csrf = Muse.util.token(40) unless req.session.csrf
	return req.session.csrf
	
exports.check = (options)->
	return (req, res, next)->
		Muse.log 'checking csrf:',req.session.csrf
		if req.method.toLowerCase() == 'post'
			unless req.body.csrf and req.body.csrf == req.session.csrf or req.url in exempt
				return next new Error "Cross-site request forgery attempt discovered!"
			delete req.body.csrf
		res.context.csrf = Muse.csrf.token(req, res)
		return next()
		
exports.ignore =(route)->
	exempt.push route