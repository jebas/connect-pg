/**
 * 
 */
var PGStore = require('../'),
	Store = require('connect').session.Store,
	pg = require('pg');

describe('connect-pg', function () {
	beforeEach(function () {
		this.options = {pgConnect: "tcp://thetester:password@localhost/pgstore"};
		this.pgStore = new PGStore(this.options);
	});
	
	describe('constructor', function () {
		it('should have a constructor function', function () {
			expect(typeof PGStore).toEqual('function');
		});
		
		it('should throw exception with no options object', function () {
			expect(function () {
				var pgStore = new PGStore();
			}).toThrow();
		});
		
		it('should throw exception for missing pgConnect string', function () {
			expect(function () {
				var options = {fred: 'barney'};
				var pgStore = new PGStore(options);
			}).toThrow();
		});
		
		it("should create an object based on connect's Store", function () {
			var parent = Object.getPrototypeOf(this.pgStore);
			expect(Object.getPrototypeOf(parent)).toEqual(Store.prototype);
		});
	});
	
	describe('set function', function () {
		it('should have a set session function', function () {
			expect(typeof this.pgStore.set).toEqual('function');
		});
		
		it('should call the postgresql database', function () {
			spyOn(pg, 'connect').andCallThrough();
			this.pgStore.set('fred', {rubble: 'barney'});
			waits(1000);
			runs(function () {
				expect(pg.connect).toHaveBeenCalled();
			});
		});
		
		it('should return by using the callback function', function () {
			var callback = jasmine.createSpy();
			this.pgStore.set('fred', {rubble: 'barney'}, callback);
			waits(1000);
			runs(function () {
				expect(callback).toHaveBeenCalled();				
			});
		});
	});
	
	describe('get function', function () {
		it('should have a get session function', function () {
			expect(typeof this.pgStore.get).toEqual('function');
		});
		
		it('should feed the callback with session data', function () {
			var callback = jasmine.createSpy();
			var sessData = {'flintstone': 'fred',
					        'rubble': 'barney'};
			this.pgStore.set('bedrock', sessData);
			this.pgStore.get('bedrock', callback);				
			waits(1000);
			runs(function () {
				expect(callback.mostRecentCall.args[1]).toEqual(sessData);
			});
		});
		
		it('should return the callback with no arguments if there is no session', function () {
			var callback = jasmine.createSpy();
			this.pgStore.get('munster', callback);
			waits(1000);
			runs(function () {
				expect(callback.mostRecentCall.args.length).toEqual(0);
			});
		});
	});
	
	describe('destroy function', function () {
		it('should have a destroy function', function () {
			expect(typeof this.pgStore.destroy).toEqual('function');
		});
		
		it('should remove the session', function () {
			var callback = jasmine.createSpy();
			var sessData = {'flintstone': 'fred',
			        'rubble': 'barney'};
			this.pgStore.set('bedrock', sessData);
			waits(1000);
			runs(function () {
				this.pgStore.destroy('bedrock');				
			});
			waits(1000);
			runs(function () {
				this.pgStore.get('bedrock', callback);				
			});
			waits(1000);
			runs(function () {
				expect(callback.mostRecentCall.args.length).toEqual(0);
			});
		});
	});
	
	describe('clear function', function () {
		it('should have a clear function', function () {
			expect(typeof this.pgStore.clear).toEqual('function');
		});
	});
});