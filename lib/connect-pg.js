/*
 *  Insert code here.
 */

var pg = require('pg');
var Store = require('connect').session.Store;

var PGStore = module.exports = function PGStore(options) {
	if (options['pgConnect']) {
		this.connectStr = options['pgConnect'];
	} else {
		throw 'Missing pgConnect';
	}
};

PGStore.prototype = new Store();
PGStore.prototype.constructor = PGStore;

PGStore.prototype.set = function (sid, sessData, callback) {
	pg.connect(this.connectStr, function (err, client) {});
	callback && callback();
};

PGStore.prototype.get = function () {};