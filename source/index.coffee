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

    @fromLastMigration: (migration) ->
      state = new State
        lastMigrationName: migration.name
        lastMigrationTimestamp: migration.timestamp

    constructor: (props) ->
      $assign this, props

  class MemoryStateStore
    stateObject: null

    constructor: (props) ->
      $assign this, props
      @stateObject ?= {}

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

    sortByDateAscending: ->
      collection = @collection.sort (a, b) -> a.getDate() - b.getDate()
      new Migrations collection: collection

    sortByDateDescending: ->
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

    forMigratingUp: (fromTimestamp, toTimestamp) ->
      this
        .afterTimestamp(fromTimestamp)
        .beforeIncludingTimestamp(toTimestamp)
        .sortByDateAscending()

    forMigratingDown: (fromTimestamp, toTimestamp) ->
      this
        .beforeIncludingTimestamp(fromTimestamp)
        .afterTimestamp(toTimestamp)
        .sortByDateDescending()

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

    addMigrations: (args...) ->
      @addMigration migration for migration in args

    runUpMigration: (migration, done) ->
      migration.up (error) =>
        return done error if error?
        state = State.fromLastMigration migration
        @stateStore.save state, done

    runDownMigration: (migration, done) ->
      migration.down (error) =>
        return done error if error?
        previousMigration = @migrations
          .sortByDateAscending()
          .getMigrationBefore(migration)
        state = State.fromLastMigration previousMigration
        @stateStore.save state, done

    runDownMigrations: (fromTimestamp, toTimestamp, done) ->
      migrationsToRun = @migrations.forMigratingDown fromTimestamp, toTimestamp
      $asyncEachSeries migrationsToRun.toArray(), @runDownMigration.bind(this), done

    runUpMigrations: (fromTimestamp, toTimestamp, done) ->
      migrationsToRun = @migrations.forMigratingUp fromTimestamp, toTimestamp
      $asyncEachSeries migrationsToRun.toArray(), @runUpMigration.bind(this), done

    migrate: (args..., done) ->
      @stateStore.fetch (error, state) =>
        return done error if error?

        targetTimestamp = args[0]
        targetDate = $getTimestampDate targetTimestamp

        currentTimestamp = state.lastMigrationTimestamp
        currentDate = $getTimestampDate currentTimestamp

        isDownMigration = targetDate? and currentDate? and targetDate < currentDate

        return @runDownMigrations currentTimestamp, targetTimestamp, done if isDownMigration
        return @runUpMigrations currentTimestamp, targetTimestamp, done

  BocoMigrate =
    BocoMigrateError: BocoMigrateError
    IrreversibleMigration: IrreversibleMigration
    NotImplemented: NotImplemented
    Migration: Migration
    State: State
    MemoryStateStore: MemoryStateStore
    Migrations: Migrations
    Migrator: Migrator

module.exports = configure()
