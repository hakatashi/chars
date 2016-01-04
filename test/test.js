const assert = require('assert');
const chars = require('../');

describe('Basic Usage', () => {
	it('basically works', () => {
		assert.deepStrictEqual(chars('foo bar'), ['f', 'o', 'o', ' ', 'b', 'a', 'r']);
	});
});
