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
	pg.connect(this.connectStr, function (err, client) {
		client.query('select set_session_data($1, $2)', 
				[sid, JSON.stringify(sessData)], 
				function () {
					callback && callback();					
		});
	});
};

PGStore.prototype.get = function (sid, callback) {
	pg.connect(this.connectStr, function (err, client) {
		client.query('select get_session_data($1)', [sid,], function (err, result) {
			if (result.rows[0].get_session_data) {
				callback(null, JSON.parse(result.rows[0].get_session_data));
			} else {
				callback();
			}
		});
	});
};

PGStore.prototype.destroy = function (sid, callback) {
	pg.connect(this.connectStr, function (err, client) {
		client.query('select destroy_session($1)', [sid,], function () {
			callback && callback();
		});
	});
};

PGStore.prototype.clear = function (callback) {
	pg.connect(this.connectStr, function (err, client) {
		client.query('select clear_sessions()', function () {
			callback && callback();
		});
	});
};

PGStore.prototype.length = function (callback) {
	pg.connect(this.connectStr, function (err, client) {
		client.query('select count_sessions()', function (err, result) {
			callback(null, result.rows[0].count_sessions);
		});
	});
};