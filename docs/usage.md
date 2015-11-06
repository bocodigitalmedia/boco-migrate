## Usage

    BocoMigrate = require "boco-migrate"

    # Used by this script to define and run tests
    assert = require "assert"
    tests = []
    tests.add = (name, fn) -> @push name: name, fn: fn

### Defining Migrations

    class AddMessageMigration extends BocoMigrate.Migration

      constructor: (name, timestamp, messages) ->
        @name = name
        @timestamp = timestamp
        @messages = messages
        @message = "Message from #{@name}"

      up: (done) ->
        done null, @messages.push(@message)

      down: (done) ->
        done null, @messages.pop()

    messages = []

    migration1 = new AddMessageMigration "migration1", "2012-01-01T00:00:00.000Z", messages
    migration2 = new AddMessageMigration "migration2", "2012-01-01T00:00:00.001Z", messages
    migration3 = new AddMessageMigration "migration3", "2012-03-01T10:35:25.034Z", messages

### Create a State Store

    stateObject = Object.create null
    stateStore = new BocoMigrate.MemoryStateStore stateObject: stateObject

### Create a Migrator

    migrator = new BocoMigrate.Migrator stateStore: stateStore

### Add Migrations

    # The order added does not matter, they will be sorted by timestamp
    migrator.addMigration migration2
    migrator.addMigration migration3
    migrator.addMigration migration1

### Run all migrations

    tests.add "run all migrations", (done) ->

      migrator.up (error) ->
        return done error if error?

        console.log "messages", messages
        console.log "migrator.state", migrator.state
        console.log "stateObject", stateObject

        assert.equal 3, messages.length
        assert.equal migration3.message, messages[2]

        assert.equal migration3.name, migrator.state.lastMigrationName
        assert.equal migration3.timestamp, migrator.state.lastMigrationTimestamp

        assert.equal migration3.name, migrator.state.lastMigrationName
        assert.equal migration3.timestamp, migrator.state.lastMigrationTimestamp

        done()

### Migrate to the specified timestamp

    tests.add "migrate to the specified timestamp", (done) ->
        return done()

        migrator.migrate migration2.timestamp, (error) ->
          return done error if error?
          console.log messages
          assert.equal 2, messages.length
          assert.equal "message from migration2", messages[1]
          done()


    runTest = (test, done) ->
      console.log "* #{test.name}"
      test.fn.call null, done

    require("async").eachSeries tests, runTest, (error) -> throw error if error?
