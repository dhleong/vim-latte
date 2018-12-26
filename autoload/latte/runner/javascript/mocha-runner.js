'use strict';
/*
 * NOTE: this is based on the JSONStream runner (plus the
 * cleanCycles function from the JSON runner) from Mocha,
 * modified to include `actual` and `expected` in fails.
 */
/**
 * @module LatteRunner
 */
/**
 * Module dependencies.
 */

/**
 * Expose `List`.
 */

exports = module.exports = List;

/**
 * Initialize a new `LatteRunner` test reporter.
 *
 * @public
 * @name LatteRunner
 * @class LatteRunner
 * @memberof Mocha.reporters
 * @extends Mocha.reporters.Base
 * @api public
 * @param {Runner} runner
 */
function List(runner) {
    // var Base = require('mocha').reporters.Base;
    // Base.call(this, runner);

    var self = this;
    var total = runner.total;

    runner.on('start', function() {
        console.log(JSON.stringify(['start', {total: total}]));
    });

    runner.on('pass', function(test) {
        console.log(JSON.stringify(['pass', clean(test)]));
    });

    runner.on('fail', function(test, err) {
        test = clean(test);
        test.err = err.message;
        test.stack = err.stack || null;
        test.actual = cleanCycles(err.actual);
        test.expected = cleanCycles(err.expected);
        test.showDiff = err.showDiff;
        console.log(JSON.stringify(['fail', test]));
    });

    runner.once('end', function() {
        process.stdout.write(JSON.stringify(['end', self.stats]));
    });
}

/**
 * Return a plain-object representation of `test`
 * free of cyclic properties etc.
 *
 * @api private
 * @param {Object} test
 * @return {Object}
 */
function clean(test) {
    return {
        title: test.title,
        fullTitle: test.fullTitle(),
        duration: test.duration,
        currentRetry: test.currentRetry()
    };
}

/**
 * Replaces any circular references inside `obj` with '[object Object]'
 *
 * @api private
 * @param {Object} obj
 * @return {Object}
 */
function cleanCycles(obj) {
    if (!obj) return;

    var cache = [];
    return JSON.parse(
        JSON.stringify(obj, function(key, value) {
            if (typeof value === 'object' && value !== null) {
                if (cache.indexOf(value) !== -1) {
                    // Instead of going in a circle, we'll print [object Object]
                    return '' + value;
                }
                cache.push(value);
            }

            return value;
        })
    );
}
