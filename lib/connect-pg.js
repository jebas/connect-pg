/*
 *  Insert code here.
 */

var pg = require('pg'),
	Store = require('connect').session.Store,
	pgConnStr = '';

function pgConnect (callback) {
	pg.connect(pgConnStr, function (err, client) {
		if (err) {
			console.log(err.message);
		}
		if (client) {
			callback(client);
		}
	});
}

function reportErr (err) {
	if (err) {
		console.log(JSON.stringify(err));
	}
};

var PGStore = module.exports = function PGStore(options) {
	if (options['pgConnect']) {
		pgConnStr = options['pgConnect'];
	} else {
		throw 'Missing pgConnect';
	}
};

PGStore.prototype = new Store();
PGStore.prototype.constructor = PGStore;

PGStore.prototype.set = function (sid, sessData, callback) {
	pgConnect(function (client) {
		var expiration = null;
		if (sessData.cookie) {
			if (sessData.cookie.expires) {
				expiration = sessData.cookie.expires;
			}
		}
		client.query('select web.set_session_data($1, $2, $3)', 
				[sid, JSON.stringify(sessData), expiration],
				function (err, result) {
					reportErr(err);
					if (result) {
						callback && callback();
					}
		});
	});
};

PGStore.prototype.get = function (sid, callback) {
	pgConnect(function (client) {
		client.query('select web.get_session_data($1)', [sid,], function (err, result) {
			reportErr(err);
			if (result) {
				if (result.rows[0].get_session_data) {
					callback(null, JSON.parse(result.rows[0].get_session_data));
				} else {
					callback();
				}
			}
		});
	});
};

PGStore.prototype.destroy = function (sid, callback) {
	pgConnect(function (client) {
		client.query('select web.destroy_session($1)', [sid,], function (err, result) {
			reportErr(err);
			if (result) {
				callback && callback();
			}
		});
	});
};

PGStore.prototype.clear = function (callback) {
	pgConnect(function (client) {
		client.query('select web.clear_sessions()', function (err, result) {
			reportErr(err);
			if (result) {
				callback && callback();
			}
		});
	});
};

PGStore.prototype.length = function (callback) {
	pgConnect(function(client){
		client.query('select web.count_sessions()', function (err, result) {
			reportErr(err);
			if (result) {
				callback(null, result.rows[0].count_sessions);
			}
		});
	});
};

PGStore.prototype.all = function (callback) {
	pgConnect(function (client) {
		var sidArray = [];
		client.query('select web.all_session_ids()', function (err, result) {
			reportErr(err);
			if (result) {
				for(var i = 0, l = result.rows.length; i < l; i++) {
					sidArray.push(result.rows[i].all_session_ids);
				}
				callback(null, sidArray);
			}
		});
	});
};
