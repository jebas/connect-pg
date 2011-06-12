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
		this.sessID1 = "bedrockBoys";
		this.sessData1 = {'flintstone': 'fred',
				'rubble': 'barney'};
		this.sessID2 = "bedrockGirls";
		this.sessData2 = {'flintstone': 'wilma',
				'rubble': 'betty'};
		this.callback1 = jasmine.createSpy();
		this.callback2 = jasmine.createSpy();
	});
	
	afterEach(function () {
		this.pgStore.destroy(this.sessID1);
		this.pgStore.destroy(this.sessID2);
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
			this.pgStore.set(this.sessID1, this.sessData1);
			waits(1000);
			runs(function () {
				expect(pg.connect).toHaveBeenCalled();
			});
		});
		
		it('should return by using the callback function', function () {
			this.pgStore.set(this.sessID1, this.sessData1, this.callback1);
			waits(1000);
			runs(function () {
				expect(this.callback1).toHaveBeenCalled();				
			});
		});
	});
	
	describe('get function', function () {
		it('should have a get session function', function () {
			expect(typeof this.pgStore.get).toEqual('function');
		});
		
		it('should feed the callback with session data', function () {
			this.pgStore.set(this.sessID1, this.sessData1);
			waits(1000);
			runs(function () {
				this.pgStore.get(this.sessID1, this.callback1);				
			});
			waits(1000);
			runs(function () {
				expect(this.callback1.mostRecentCall.args[1]).toEqual(this.sessData1);
			});
		});
		
		it('should return the callback with no arguments if there is no session', function () {
			this.pgStore.get('munster', this.callback1);
			waits(1000);
			runs(function () {
				expect(this.callback1.mostRecentCall.args.length).toEqual(0);
			});
		});
	});
	
	describe('destroy function', function () {
		it('should have a destroy function', function () {
			expect(typeof this.pgStore.destroy).toEqual('function');
		});
		
		it('should remove the session', function () {
			this.pgStore.set(this.sessID1, this.sessData1);
			this.pgStore.set(this.sessID2, this.sessData2);
			waits(1000);
			runs(function () {
				this.pgStore.destroy(this.sessID1);				
			});
			waits(1000);
			runs(function () {
				this.pgStore.get(this.sessID1, this.callback1);
				this.pgStore.get(this.sessID2, this.callback2);
			});
			waits(1000);
			runs(function () {
				expect(this.callback1.mostRecentCall.args.length).toEqual(0);
				expect(this.callback2.mostRecentCall.args[1]).toEqual(this.sessData2);
			});
		});
	});
	
	describe('clear function', function () {
		it('should have a clear function', function () {
			expect(typeof this.pgStore.clear).toEqual('function');
		});
	});
});