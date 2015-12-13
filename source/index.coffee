configure = ($ = {}) ->
  $async = $.async ? require "async"
  $lodash = $.lodash ? require "lodash"

  class MigrateError extends Error
    constructor: (props) ->
      @[key] = val for own key, val of props
      Error.captureStackTrace @, @constructor
      @name ?= @constructor.name

  class IdentityNotUnique extends MigrateError
    message: "Identity not unique"

  class MigrationNotFound extends MigrateError
    message: "Migration not found"

  class IrreversibleMigration extends MigrateError
    message: "Irreversible Migration"

  class NotImplemented extends MigrateError
    message: "Not implemented"

  class Migration
    id: null

    constructor: (props) ->
      @[key] = val for own key, val of props

    up: (done) ->
      done new NotImplemented

    down: (done) ->
      done new IrreversibleMigration

  class StorageAdapter
    latestMigrationId: null

    constructor: (props) ->
      @[key] = val for own key, val of props

    setLatestMigrationId: (id, done) ->
      done null, (@latestMigrationId = id)

    getLatestMigrationId: (done) ->
      done null, @latestMigrationId

  class Migrator
    migrations: null
    storageAdapter: null

    constructor: (props) ->
      @[key] = val for own key, val of props
      @migrations ?= []
      @storageAdapter ?= new StorageAdapter

    addMigration: (migration) ->
      migration = new Migration(migration) unless migration instanceof Migration
      @migrations.push migration
      migration

    findMigrationById: (id) ->
      index = @findMigrationIndexById(id)
      @migrations[index]

    findMigrationIndexById: (id) ->
      index = $lodash.findIndex @migrations, (migration) -> migration.id is id
      throw new MigrationNotFound unless index? and index > -1
      return index

    migrate: (targetId, done) ->
      @storageAdapter.getLatestMigrationId (error, latestId) =>
        return done(error) if error?

        latestIndex = @findMigrationIndexById(latestId) if latestId?
        targetIndex = @findMigrationIndexById(targetId) if targetId?
        latestIndex ?= -1
        targetIndex ?= @migrations.length - 1

        return done() if targetIndex is latestIndex

        # [-,L,-,-,T,-] start: L + 1, end: T + 1
        #  0 1 2 3 4 5
        if targetIndex > latestIndex
          startIndex = latestIndex + 1
          migrations = @migrations.slice(startIndex, targetIndex + 1)
          return @runUpMigrations migrations, done

        # [-,T,-,-,L,-] start: T+1, end: L
        #  0 1 2 3 4 5
        if targetIndex < latestIndex
          startIndex = targetIndex + 1
          migrations = @migrations.slice(startIndex, latestIndex + 1).reverse()
          return @runDownMigrations migrations, done

    rollback: (done) ->
      @storageAdapter.getLatestMigrationId (error, latestId) =>
        return done() unless latestId?
        latestMigration = @findMigrationById latestId
        @runDownMigration latestMigration, done

    runUpMigration: (migration, done) ->
      migration.up (error) =>
        return done error if error?
        @storageAdapter.setLatestMigrationId migration.id, done

    runUpMigrations: (migrations, done) ->
      $async.eachSeries migrations, @runUpMigration.bind(@), done

    runDownMigration: (migration, done) ->
      migration.down (error) =>
        return done error if error?

        index = @findMigrationIndexById migration.id
        latestMigration = @migrations[index - 1]
        @storageAdapter.setLatestMigrationId latestMigration?.id, done

    runDownMigrations: (migrations, done) ->
      $async.eachSeries migrations, @runDownMigration.bind(@), done

  BocoMigrate =
    MigrateError: MigrateError
    IrreversibleMigration: IrreversibleMigration
    NotImplemented: NotImplemented
    MigrationNotFound: MigrationNotFound

    Migration: Migration
    StorageAdapter: StorageAdapter
    Migrator: Migrator

module.exports = configure()
