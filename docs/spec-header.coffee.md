    _tests = []
    assert = require "assert"

    test = (name, fn) ->
      console.log "found test #{name}"
      _tests.push name: name, fn: fn

    _runTest = (test, done) ->
      console.log test.name
      test.fn done

    _runTests = (done) ->
      console.log "run tests"
      require("async").eachSeries _tests, _runTest, done
