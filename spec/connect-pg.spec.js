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
	
	describe('set function', function (){
		it('should have a set session function', function () {
			expect(typeof this.pgStore.set).toEqual('function');
		});
		
		it('should call the postgresql database', function () {
			spyOn(pg, 'connect');
			this.pgStore.set('fred', {rubble: 'barney'}, function () {});
			expect(pg.connect).toHaveBeenCalled();
		});
		
		it('should return by using the callback function', function () {
			var callback = jasmine.createSpy();
			this.pgStore.set('fred', {rubble: 'barney'}, callback);
			expect(callback).toHaveBeenCalled();
		});
		
		it('should work without a callback function', function () {
			var pgStore = this.pgStore;
			expect(function () {
				pgStore.set('fred', {rubble: 'barney'});
			}).not.toThrow();
		});
	});
});