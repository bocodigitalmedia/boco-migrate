assert = require "assert"
_tests = []
test = (name, fn) -> _tests.push name: name, fn: fn

BocoMigrate = require "boco-migrate"

stateStore = new BocoMigrate.MemoryStateStore

migrator = new BocoMigrate.Migrator stateStore: stateStore

messages = []

migration1 = new BocoMigrate.Migration
  name: "migration1"
  timestamp: "2015-01-01T00:00:00Z"
  up: (done) -> messages.push "message from #{@name}"; done()
  down: (done) -> messages.pop(); done()

class AddMessage extends BocoMigrate.Migration
  constructor: (name, timestamp, messages) ->
    super name: name, timestamp: timestamp
    @messages = messages

  up: (done) -> @messages.push "message from #{@name}"; done()
  down: (done) -> @messages.pop(); done()

migration2 = new AddMessage "migration2", "2015-01-02T01:30:00Z", messages
migration3 = new AddMessage "migration3", "2015-03-25T22:15:33Z", messages

migrator.addMigrations migration1, migration2, migration3

test "migrating to the latest version", (done) ->

  migrator.migrate (error) ->
    return done error if error?
    assert.equal 3, messages.length
    assert.equal "message from migration3", messages[2]
    done()

test "migrating down to a specific version", (done) ->

  migrator.migrate migration1.timestamp, (error) ->
    return done error if error?
    assert.equal 1, messages.length
    assert.equal "message from migration1", messages[0]
    done()

test "migrating up to a specific version", (done) ->

  migrator.migrate migration2.timestamp, (error) ->
    return done error if error?
    assert.equal 2, messages.length
    assert.equal "message from migration2", messages[1]
    done()
_runTest = (test, done) ->
  console.log "* #{test.name}"
  test.fn done
require("async").eachSeries _tests, _runTest, (error) ->
  throw error if error?