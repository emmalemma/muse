vows = require 'vows'
should = require 'should'
Muse = require('muse')

model = Muse.model

exports.validators = vows.describe('validators').addBatch
	'@string':
		'without options':
			topic: -> model.validators.string()
			'validates strings':(string)->should.not.exist string("string")
			'does not validate non-strings':(string)->
				string(new Number).should.equal 'must be a string'
				string(new Boolean).should.equal 'must be a string'
				string(new Object).should.equal 'must be a string'
				string(new Array).should.equal 'must be a string'
		'with matches:':
			'/regex/':
				topic: -> model.validators.string(matches: /regex/)
				'should return null for "regex"':(string)->should.not.exist string("regex")
				'should return "must match /regex/" for "something else"':(string)->
					string("something else").should.equal 'must match /regex/'
			"'email'":
				topic: -> model.validators.string(matches: 'email')
				'validates valid emails':(string)->
					should.not.exist string("email@email.com")
					should.not.exist string("email.2@email-now.net")
					should.not.exist string("email-me@email-happy.ly")
				'does not validate invalid emails':(string)->
					string('not an email!@email.com').should.equal 'must match email'
			
	'@object':
		'without options':
			'with {str:@string(), int:@integer()}':
				topic: -> model.validators.object({str:model.validators.string(), int:model.validators.integer()})
				'validate a proper object':(object)->console.log object({str:"test",int:12})
				"doesn't validate non-Objects":(object)->
					object(new Number).should.equal 'must be an object'
					object(new Boolean).should.equal 'must be an object'
					object(new String).should.equal 'must be an object'
				'has required fields':(object)->
					errors = object({})
					errors.str.should.equal 'required'
					errors.int.should.equal 'required'
				'validates properties':(object)->
					errors = object({int:"str", str:1})
					errors.str.should.equal 'must be a string'
					errors.int.should.equal 'must be an integer'
			'with {str:@string(optional: true)}':
				topic: -> model.validators.object({str:model.validators.string(optional: true)})
				'validates the property if present':(object)->
					object({str:1}).str.should.equal 'must be a string'
					should.not.exist object({str:'string'})
				'validates if the property is not present':(object)->
					should.not.exist object({})
			'with {obj:@object({str:@string()})}':
				topic: -> model.validators.object({obj:model.validators.object({str:model.validators.string()})})
				'validates the sub-object':(object)->
					object({}).obj.should.equal 'required'
					object({obj:'string'}).obj.should.equal 'must be an object'
				'validates properties of the sub-object':(object)->
					object({obj:{str:1}}).obj.str.should.equal 'must be a string'
					should.not.exist object({obj:{str:'string'}})
			'with {obj:@object({optional: true},{str:@string()})}':
				topic: -> model.validators.object({obj:model.validators.object({optional: true},{str:model.validators.string()})})
				'validates if the sub-object is not present':(object)->
					should.not.exist object({})
exports.validators.run()