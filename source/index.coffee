configure = (dependencies) ->

  $assign = (target, source) ->
    target[key] = val for own key,val of source

  $getTimestampDate = (timestamp) ->
    return null unless timestamp?
    return new Date timestamp

  $asyncSeries = (series, done) ->
    require("async").series series, done

  $asyncEachSeries = (series, fn, done) ->
    require("async").eachSeries series, fn, done

  class BocoMigrateError extends Error
    constructor: (props) ->
      $assign this, props
      Error.captureStackTrace @, @constructor
      @name ?= @constructor.name
      @message ?= @getDefaultMessage()

  class IrreversibleMigration extends BocoMigrateError
    migration: null
    getDefaultMessage: -> "Migration '#{@migration.name}' is irreversible."

  class NotImplemented extends BocoMigrateError
    getDefaultMessage: -> "Not implemented"

  class Migration
    name: null
    timestamp: null

    constructor: (props) ->
      $assign this, props

    up: (done) ->
      done new NotImplemented()

    down: (done) ->
      done new IrreversibleMigration(migration: this)

    getDate: ->
      new Date @timestamp

  class State
    lastMigrationName: null
    lastMigrationTimestamp: null

    constructor: (props) ->
      $assign this, props

    setLastMigration: (migration = {}) ->
      @lastMigrationTimestamp = migration.timestamp ? null
      @lastMigrationName = migration.name ? null

  class MemoryStateStore
    stateObject: null

    constructor: (props) ->
      $assign this, props

    save: (state, done) ->
      @stateObject.lastMigrationName = state.lastMigrationName
      @stateObject.lastMigrationTimestamp = state.lastMigrationTimestamp
      done()

    fetch: (done) ->
      done null, new State(@stateObject)

  class Migrations
    collection: null

    constructor: (props) ->
      $assign this, props
      @collection = if @collection? then @collection.slice() else []

    add: (migration) ->
      @collection.push migration

    getMigrationBefore: (migration) ->
      migrationIndex = @collection.indexOf(migration)
      @collection[migrationIndex - 1]

    sortAscByDate: ->
      collection = @collection.sort (a, b) -> a.getDate() - b.getDate()
      new Migrations collection: collection

    sortDescByDate: ->
      collection = @collection.sort (a, b) -> b.getDate() - a.getDate()
      new Migrations collection: collection

    afterTimestamp: (timestamp) ->
      date = $getTimestampDate timestamp
      return this unless date?

      collection = @collection.filter (migration) ->
        migration.getDate() > date

      new Migrations collection: collection

    beforeIncludingTimestamp: (timestamp) ->
      date = $getTimestampDate timestamp
      return this unless date?

      collection = @collection.filter (migration) ->
        migration.getDate() <= date

      new Migrations collection: collection

    forMigratingUpTo: (targetTimestamp, currentTimestamp) ->
      this
        .afterTimestamp(currentTimestamp)
        .beforeIncludingTimestamp(targetTimestamp)
        .sortAscByDate()

    forMigratingDownTo: (targetTimestamp, currentTimestamp) ->
      this
        .afterTimestamp(targetTimestamp)
        .beforeIncludingTimestamp(currentTimestamp)
        .sortDescByDate()

    toArray: ->
      @collection.slice()

  class Migrator
    migrations: null
    stateStore: null

    constructor: (props) ->
      $assign this, props
      @migrations ?= new Migrations()
      @stateStore ?= new MemoryStateStore()

    addMigration: (migration) ->
      @migrations.add migration

    down: (args..., done) ->
      targetTimestamp = args[0] ? null

      @stateStore.fetch (error, state) =>
        return done error if error?

        currentTimestamp = state.lastMigrationTimestamp
        migrations = @migrations.forMigratingDownTo targetTimestamp, currentTimestamp

        runMigration = (migration, done) =>

          migration.down (error) =>
            return done error if error?
            state = new State()
            previousMigration = @migrations.sortAscByDate().getMigrationBefore(migration)
            state.setLastMigration previousMigration
            @stateStore.save state, done

        $asyncEachSeries migrations.toArray(), runMigration, done

    up: (args..., done) ->
      targetTimestamp = args[0] ? null

      @stateStore.fetch (error, state) =>
        return done error if error?

        currentTimestamp = state.lastMigrationTimestamp
        migrations = @migrations.forMigratingUpTo targetTimestamp, currentTimestamp

        runMigration = (migration, done) =>
          migration.up (error) =>
            return done error if error?
            state = new State()
            state.setLastMigration migration
            @stateStore.save state, done

        $asyncEachSeries migrations.toArray(), runMigration, done

  BocoMigrate =
    IrreversibleMigration: IrreversibleMigration
    Migration: Migration
    State: State
    Migrator: Migrator
    MemoryStateStore: MemoryStateStore

module.exports = configure()
