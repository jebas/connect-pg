/*
 *  Insert code here.
 */
var Store = require('connect').session.Store;

var PGStore = module.exports = function PGStore() {};

PGStore.prototype = new Store();
PGStore.prototype.constructor = PGStore;
