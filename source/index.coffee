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

    setMigration: (migration) ->
      @lastMigrationTimestamp = migration.timestamp
      @lastMigrationName = migration.name

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

    sortByDate: (ascending = true) ->
      collection = @collection.sort (a, b) ->
        return a.getDate() - b.getDate() if ascending
        return b.getDate() - a.getDate()

      new Migrations collection: collection

    after: (timestamp) ->
      date = $getTimestampDate timestamp
      return this unless date?

      collection = @collection.filter (migration) ->
        migration.getDate() > date

      new Migrations collection: collection

    beforeIncluding: (timestamp) ->
      date = $getTimestampDate timestamp
      return this unless date?

      collection = @collection.filter (migration) ->
        migration.getDate() <= date

      new Migrations collection: collection

    toArray: ->
      @collection.slice()

  class Migrator
    migrations: null
    state: null

    constructor: (props) ->
      $assign this, props
      @migrations ?= new Migrations()
      @state ?= new State()

    addMigration: (migration) ->
      @migrations.add migration

    up: (done) ->
      migrations = @migrations
        .after(@state.lastMigrationTimestamp)
        .sortByDate()
        .toArray()

      runMigration = (migration, done) =>
        console.log "-> #{migration.name}"

        migrateUp = (done) ->
          migration.up done

        saveState = (done) =>
          @state.setMigration migration
          @stateStore.save @state, done

        $asyncSeries [migrateUp, saveState], done

      $asyncEachSeries migrations, runMigration, done

  BocoMigrate =
    IrreversibleMigration: IrreversibleMigration
    Migration: Migration
    State: State
    Migrator: Migrator
    MemoryStateStore: MemoryStateStore

module.exports = configure()
