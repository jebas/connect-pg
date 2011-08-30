/*
 *	PGStore - Connect storage in a PostgreSQL database.
 */
var Store = require('connect').session.Store;

var PGStore = module.exports = function PGStore(clientFn) {
	if (typeof clientFn != 'function') {
		throw TypeError;
	}
	this.getClient = clientFn;
};

PGStore.prototype = new Store();

PGStore.prototype.set = function (sid, sessData, callback) {
	this.getClient(function (client) {
		var expiration = null;
		if (sessData.cookie) {
			if (sessData.cookie.expires) {
				expiration = sessData.cookie.expires;
			}
		}
		client.query('select web.set_session_data($1, $2, $3)',
			[sid, JSON.stringify(sessData), expiration],
			function (err, result) {
				if (err) {
					console.log(err.message);
				}
				if (result) {
					callback && callback();
				}
			}
		);
	});
};

PGStore.prototype.get = function (sid, callback) {
	this.getClient(function (client) {
		client.query('select web.get_session_data($1)',
			[sid],
			function (err, result) {
				if (err) {
					console.log(err.message);
				}
				if (result) {
					if (result.rows.length) {
						callback(null, JSON.parse(result.rows[0].get_session_data));
					} else {
						callback(null, null);
					}
				}
			}
		);
	});
};

PGStore.prototype.destroy = function (sid, callback) {
	this.getClient(function (client) {
		client.query('select web.destroy_session($1)',
			[sid],
			function (err, result) {
				if (err) {
					console.log(err.message);
				}
				if (result) {
					callback && callback();
				}
			}
		);
	});
};

PGStore.prototype.length = function (callback) {
	this.getClient(function (client) {
		client.query('select web.count_sessions()',
			function (err, result) {
				if (err) {
					console.log(err.message);
				}
				if (result) {
					callback(null, result.rows[0].count_sessions);
				}
			}
		);
	});
};

PGStore.prototype.clear = function (callback) {
	this.getClient(function (client) {
		client.query('select web.clear_sessions()',
			function (err, result) {
				if (err) {
					console.log(err.message);
				}
				if (result) {
					callback && callback();
				}
			}
		);
	});
};