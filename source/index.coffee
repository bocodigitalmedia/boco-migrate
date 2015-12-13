configure = ($ = {}) ->
  $async = $.async ? require "async"
  $lodash = $.lodash ? require "lodash"
  $minimist = $.minimist ? require "minimist"
  $process = $.process ? process
  $path = $.path ? require "path"

  class MigrateError extends Error
    constructor: (props) ->
      super()
      @[key] = val for own key, val of props
      Error.captureStackTrace @, @constructor
      @name = @constructor.name

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
    name: null

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

    getLatestMigrationIndex: (done) ->
      @storageAdapter.getLatestMigrationId (error, latestId) =>
        return done(error) if error?
        return done(null, -1) unless latestId?
        return done(null, @findMigrationIndexById(latestId))

    getUpMigrations: (latestIndex = -1, targetIndex) ->
      targetIndex ?= @collection.length - 1
      startIndex = latestIndex + 1
      @migrations.slice(startIndex, targetIndex + 1)

    getDownMigrations: (latestIndex = -1, targetIndex) ->
      targetIndex ?= -1
      startIndex = targetIndex + 1
      @migrations.slice(startIndex, latestIndex + 1).reverse()

    migrate: (targetId, done) ->
      targetIndex = @findMigrationIndexById(targetId) if targetId?
      targetIndex ?= @migrations.length - 1

      @getLatestMigrationIndex (error, latestIndex) =>
        return done(error) if error?
        return done() if targetIndex is latestIndex

        if targetIndex > latestIndex
          migrations = @getUpMigrations latestIndex, targetIndex
          return @runUpMigrations migrations, done

        if targetIndex < latestIndex
          migrations = @getDownMigrations latestIndex, targetIndex
          return @runDownMigrations migrations, done

    rollback: (done) ->
      @getLatestMigrationIndex (error, latestIndex) =>
        return done() if latestIndex < 0
        @runDownMigration @migrations[latestIndex], done

    reset: (done) ->
      @getLatestMigrationIndex (error, latestIndex) =>
        return done(error) if error?
        migrations = @getDownMigrations latestIndex
        @runDownMigrations migrations, done

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

  class CLI

    getHelp: ->
      cmd = $path.basename $process.argv[1]
      """
      Usage: #{cmd} <options...> <command>

      options:
        -h, --help                   show this help screen
        -e, --example                show an example migrator factory
        -f, --factory=factory_path   path to the migrator factory
                                     defaults to "migrator.js"

      commands:
        migrate
          Migrate to the (optional) target migration id
        rollback
          Roll back the latest migration
        reset
          Roll back all migrations
        info
          Show migration information

      factory:
        A javascript file that exports a single async factory method,
        returning a migrator instance for the CLI.
      """

    showHelp: (code = 0) ->
      $process.stdout.write @getHelp() + "\n"
      $process.exit code

    getExample: ->
      """
      // example factory.js
      module.exports = function(done) {
        require("my-database-lib").connect(function(error, connection) {
          if(error != null) { return done(error); }

          var BocoMigrate = require("boco-migrate");
          var MyStorageAdapter = require("my-database-storage-adapter");

          var storageAdapter = new MyStorageAdapter({
            connection: connection
          });

          var migrator = new BocoMigrate.Migrator({
            storageAdapter: storageAdapter
          });

          var migrations = require("./migrations").configure({
            connection: connection
          });

          migrator.addMigrations(migrations);
          return done(null, migrator);
        });
      };
      """

    example: ->
      $process.stdout.write @getExample() + "\n"

    getMigrator: (factoryPath, done) ->
      path = $path.resolve $process.cwd(), factoryPath
      path = "./#{path}" unless /^[\\\/]/.test(path)
      require(path)(done)

    migrate: (migrator, targetId, done) ->
      migrator.migrate targetId, done

    rollback: (migrator, done) ->
      migrator.rollback done

    reset: (migrator, done) ->
      migrator.reset done

    info: (migrator, done) ->
      migrator.getLatestMigrationIndex (error, latestIndex) ->
        return done error if error?
        migrations = migrator.migrations
        pendingCount = migrations.length - 1 - latestIndex

        $process.stdout.write "key: [ - previous | > latest | + pending ]\n\n"

        migrations.forEach (migration, index) ->
          {id, name = ''} = migration

          if index < latestIndex then key = "-"
          if index is latestIndex then key = ">"
          if index > latestIndex then key = "+"

          line = [key, id, name].join(" ")
          $process.stdout.write line + "\n"

        $process.stdout.write "\nYou have #{pendingCount} pending migrations\n"
        done()

    getParams: ->
      argv = $process.argv.slice(2)

      minimist = $minimist argv,
        boolean: ["example", "help"]
        string: ["factory"]
        default:
          factory: "migrator.js"
        alias:
          help: "h"
          factory: "f"
          example: "e"

      params =
        help: minimist.help
        example: minimist.example
        command: minimist._[0]
        factory: minimist.factory
        args: minimist._.slice(1)

    run: ->
      params = @getParams()
      {help, example, command, factory, args} = params
      return @showHelp() if help
      return @showExample() if example

      done = (error) ->
        throw error if error?
        $process.exit()

      return done "missing option: --factory" unless factory?

      @getMigrator factory, (error, migrator) =>
        return done(error) if error?

        switch command
          when "migrate" then @migrate migrator, args[0], done
          when "rollback" then @rollback migrator, done
          when "reset" then @reset migrator, done
          when "info" then @info migrator, done
          else @showHelp 1

  BocoMigrate =
    MigrateError: MigrateError
    IrreversibleMigration: IrreversibleMigration
    NotImplemented: NotImplemented
    MigrationNotFound: MigrationNotFound

    Migration: Migration
    StorageAdapter: StorageAdapter
    Migrator: Migrator
    CLI: CLI

module.exports = configure()
