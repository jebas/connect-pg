/**
 * 
 */
var PGStore = require('../'),
	Store = require('connect').session.Store,
	pg = require('pg');

describe('connect-pg', function () {
	beforeEach(function () {
		this.options = {pgConnect: "tcp://nodepg:password@localhost/pgstore"};
		this.pgStore = new PGStore(this.options);
		this.sessID1 = "bedrockBoys";
		this.sessData1 = {
				'flintstone': 'fred',
				'rubble': 'barney'};
		this.sessID2 = "bedrockGirls";
		this.sessData2 = {
				'flintstone': 'wilma',
				'rubble': 'betty'};
		this.callback1 = jasmine.createSpy();
		this.callback1Prev = 0;
		this.callback1Called = function () {
			return this.callback1Prev != this.callback1.callCount;
		};
		this.callback2 = jasmine.createSpy();
		this.callback2Prev = 0;
		this.callback2Called = function () {
			return this.callback2Prev != this.callback2.callCount;
		};
	});
	
	afterEach(function () {
		delete this.sessData1;
		delete this.sessData2;
		this.pgStore.clear();
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
			var previousCallbackCount = this.callback1.callCount;
			spyOn(pg, 'connect').andCallThrough();
			this.pgStore.set(this.sessID1, this.sessData1, this.callback1);
			waitsFor(this.callback1Called, 'Waiting on the callback', 10000);
			runs(function () {
				expect(pg.connect).toHaveBeenCalled();
			});
		});
		
		it('should return by using the callback function', function () {
			var previousCallbackCounter = this.callback1.callCount;
			this.pgStore.set(this.sessID1, this.sessData1, this.callback1);
			waitsFor(this.callback1Called, 'Waiting on the callback', 10000);
			runs(function () {
				expect(this.callback1).toHaveBeenCalled();
			});
		});
		
		it('should accept expiration data as a date', function () {
			var pgStore = this.pgStore;
			var sessID1 = this.sessID1;
			var sessData1 = this.sessData1;
			sessData1['cookie'] = {'expires': new Date};
			expect(function () {
				pgStore.set(sessID1, sessData1);
			}).not.toThrow();
		});
		
		it('should accept expiration date as a string', function () {
			var theDate = new Date;
			var pgStore = this.pgStore;
			var sessID1 = this.sessID1;
			var sessData1 = this.sessData1;
			sessData1['cookie'] = {'expires': theDate.toString()};
			expect(function () {
				pgStore.set(sessID1, sessData1);
			}).not.toThrow();
		});
		
		/*
		it('should keep cookie.expire and expiration the same', function () {
			sessID1 = this.sessID1;
			var theDate = new Date;
			theDate.setDate(theDate.getDate() + 1);
			this.sessData1['cookie'] = {'expires': theDate};
			this.pgStore.set(this.sessID1, this.sessData1, this.callback1);
			waitsFor(this.callback1Called, 'Waiting for callback', 10000);
			runs(function () {
				pg.connect(this.options.pgConnect, function (err, client) {
					client.query('select expiration from web.session where sess_id = $1',
							[sessID1,],
							function (err, result) {
								pgDate = new Date(result.rows[0].expiration);
								expect(theDate).toEqual(pgDate);
					});
				});
			});
		});
		*/
	});
	
	describe('get function', function () {
		it('should have a get session function', function () {
			expect(typeof this.pgStore.get).toEqual('function');
		});
		
		it('should feed the callback with session data', function () {
			this.pgStore.set(this.sessID1, this.sessData1, this.callback1);
			waitsFor(this.callback1Called, 'Waiting on callback', 10000);
			runs(function () {
				this.callback1Prev = this.callback1.callCount;
				this.pgStore.get(this.sessID1, this.callback1);
				waitsFor(this.callback1Called, 'Waiting on get callback', 10000);
				runs(function () {
					expect(this.callback1.mostRecentCall.args[1]).toEqual(this.sessData1);
				});
			});
		});
		
		it('should return the callback with no arguments if there is no session', function () {
			this.pgStore.get('munster', this.callback1);
			waitsFor(this.callback1Called, 'Waiting for callback', 10000);
			runs(function () {
				expect(this.callback1.mostRecentCall.args.length).toEqual(0);
			});
		});
		
		it('should not retrieve an expired session', function () {
			var theDate = new Date;
			theDate.setDate(theDate.getDate() - 1);
			this.sessData1['cookie'] = {'expires': theDate};
			this.pgStore.set(this.sessID1, this.sessData1, this.callback1);
			waitsFor(this.callback1Called, 'Waiting for callback', 10000);
			runs(function () {
				this.callback1Prev = this.callback1.callCount;
				this.pgStore.get(this.sessID1, this.callback1);
				waitsFor(this.callback1Called, 'Waiting on get callback', 10000);
				runs(function () {
					expect(this.callback1.mostRecentCall.args.length).toEqual(0);
				});
			});
		});
	});
	
	describe('destroy function', function () {
		it('should have a destroy function', function () {
			expect(typeof this.pgStore.destroy).toEqual('function');
		});
		
		it('should remove the session', function () {
			this.pgStore.set(this.sessID1, this.sessData1, this.callback1);
			this.pgStore.set(this.sessID2, this.sessData2, this.callback2);
			waitsFor(function () {
				return this.callback1Called() && this.callback2Called();
			}, 'Waiting for sets to complete', 10000);
			runs(function () {
				this.callback1Prev = this.callback1.callCount;
				this.callback2Prev = this.callback2.callCount;
				this.pgStore.destroy(this.sessID1, this.callback1);
				waitsFor(this.callback1Called, 'Waiting on destroy', 10000);
				runs(function () {
					this.callback1Prev = this.callback1.callCount;
					this.callback2Prev = this.callback2.callCount;
					this.pgStore.get(this.sessID1, this.callback1);
					this.pgStore.get(this.sessID2, this.callback2);
					waitsFor(function () {
						return this.callback1Called() && this.callback2Called();
					}, 'Waiting for sets to complete', 10000);
					runs(function () {
						expect(this.callback1.mostRecentCall.args.length).toEqual(0);
						expect(this.callback2.mostRecentCall.args[1]).toEqual(this.sessData2);
					});
				});
			});
		});
		
		it('should accept a callback function', function () {
			this.pgStore.destroy(this.sessID1, this.callback1);
			waitsFor(this.callback1Called, 'Waiting for callback.', 10000);
			runs(function () {
				expect(this.callback1).toHaveBeenCalled();				
			});
		});		
	});
	
	describe('clear function', function () {
		it('should have a clear function', function () {
			expect(typeof this.pgStore.clear).toEqual('function');
		});
		
		it('should remove all of the sessions', function () {
			this.pgStore.set(this.sessID1, this.sessData1, this.callback1);
			this.pgStore.set(this.sessID2, this.sessData2, this.callback2);
			waitsFor(function () {
				return this.callback1Called() && this.callback2Called();
			}, 'Waiting for sets to complete', 10000);
			runs(function () {
				this.callback1Prev = this.callback1.callCount;
				this.callback2Prev = this.callback2.callCount;
				this.pgStore.clear(this.callback1);
				waitsFor(this.callback1Called, 'Waiting in clear callback', 10000);
				runs(function () {
					this.callback1Prev = this.callback1.callCount;
					this.callback2Prev = this.callback2.callCount;
					this.pgStore.get(this.sessID1, this.callback1);
					this.pgStore.get(this.sessID2, this.callback2);
					waitsFor(function () {
						return this.callback1Called() && this.callback2Called();
					}, 'Waiting for gets to complete', 10000);
					runs(function () {
						expect(this.callback1.mostRecentCall.args.length).toEqual(0);
						expect(this.callback2.mostRecentCall.args.length).toEqual(0);
					});
				});
			});
		});
		
		it('should accept a callback function', function () {
			this.pgStore.clear(this.callback1);
			waitsFor(this.callback1Called, 'Waiting for callback', 10000);
			runs(function () {
				expect(this.callback1).toHaveBeenCalled();				
			});
		});
	});
	
	describe('length function', function () {
		it('should have a length function', function () {
			expect(typeof this.pgStore.length).toEqual('function');
		});
		
		it('should return to the callback the total number of sessions', function () {
			this.pgStore.set(this.sessID1, this.sessData1, this.callback1);
			this.pgStore.set(this.sessID2, this.sessData2, this.callback2);
			waitsFor(function () {
				return this.callback1Called() && this.callback2Called();
			}, 'Waiting for sets to complete', 10000);
			runs(function () {
				this.callback1Prev = this.callback1.callCount;
				this.callback2Prev = this.callback2.callCount;
				this.pgStore.length(this.callback1);
				waitsFor(this.callback1Called, 'Waiting for length callback', 10000);
				runs(function () {
					expect(this.callback1.mostRecentCall.args[1]).toEqual(2);
				});
			});
		});
		
		it('should not count expired sessions', function () {
			var Date1 = new Date;
			Date1.setDate(Date1.getDate() + 1);
			this.sessData1['cookie'] = {'expires': Date1};
			var Date2 = new Date;
			Date2.setDate(Date2.getDate() - 1);
			this.sessData2['cookie'] = {'expires': Date2};
			this.pgStore.set(this.sessID1, this.sessData1, this.callback1);
			this.pgStore.set(this.sessID2, this.sessData2, this.callback2);
			waitsFor(function () {
				return this.callback1Called() && this.callback2Called();
			}, 'Waiting for sets to complete', 10000);
			runs(function () {
				this.callback1Prev = this.callback1.callCount;
				this.callback2Prev = this.callback2.callCount;
				this.pgStore.length(this.callback1);
				waitsFor(this.callback1Called, 'Waiting for length callback', 10000);
				runs(function () {
					expect(this.callback1.mostRecentCall.args[1]).toEqual(1);
				});
			});
		});
	});
	
	describe('all function', function () {
		it('should have an all function', function () {
			expect(typeof this.pgStore.all).toEqual('function');
		});
		
		it('should return an array of session ids', function () {
			this.pgStore.set(this.sessID1, this.sessData1, this.callback1);
			this.pgStore.set(this.sessID2, this.sessData2, this.callback2);
			waitsFor(function () {
				return this.callback1Called() && this.callback2Called();
			}, 'Waiting for sets to complete', 10000);
			runs(function () {
				this.callback1Prev = this.callback1.callCount;
				this.callback2Prev = this.callback2.callCount;
				this.pgStore.all(this.callback1);
				waitsFor(this.callback1Called, 'Waiting for all callback', 10000);
				runs(function () {
					expect(this.callback1.mostRecentCall.args[1].length).toEqual(2);
					expect(this.callback1.mostRecentCall.args[1]).toContain(this.sessID1);
					expect(this.callback1.mostRecentCall.args[1]).toContain(this.sessID2);
				});
			});
		});
		
		it('should not list any expired sessions', function () {
			var Date1 = new Date;
			Date1.setDate(Date1.getDate() + 1);
			this.sessData1['cookie'] = {'expires': Date1};
			var Date2 = new Date;
			Date2.setDate(Date2.getDate() - 1);
			this.sessData2['cookie'] = {'expires': Date2};
			this.pgStore.set(this.sessID1, this.sessData1, this.callback1);
			this.pgStore.set(this.sessID2, this.sessData2, this.callback2);
			waitsFor(function () {
				return this.callback1Called() && this.callback2Called();
			}, 'Waiting for sets to complete', 10000);
			runs(function () {
				this.callback1Prev = this.callback1.callCount;
				this.callback2Prev = this.callback2.callCount;
				this.pgStore.all(this.callback1);
				waitsFor(this.callback1Called, 'Waiting for all callback', 10000);
				runs(function () {
					expect(this.callback1.mostRecentCall.args[1].length).toEqual(1);
					expect(this.callback1.mostRecentCall.args[1]).toContain(this.sessID1);
				});
			});
		});
	});
});