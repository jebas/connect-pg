/**
 * 
 */
var PGStore = require('../'),
	Store = require('connect').session.Store;

describe('connect-pg', function () {
	it('should have a constructor function', function () {
		expect(typeof PGStore).toEqual('function');
	});
	
	it("should create an object based on connect's Store", function () {
		var pgStore = new PGStore();
		var parent = Object.getPrototypeOf(pgStore);
		expect(Object.getPrototypeOf(parent)).toEqual(Store.prototype);
	});
});