# boco-migrate

![npm version](https://img.shields.io/npm/v/boco-migrate.svg)
![npm license](https://img.shields.io/npm/l/boco-migrate.svg)
![dependencies](https://david-dm.org/bocodigitalmedia/boco-migrate.png)

Migrate all your things (not just databases)!

## Table of Contents

* [Installation]
* [Usage]
  * [Migrating]
  * [Rolling Back]
  * [Resetting]
  * [Storage Adapters]
    * [File Storage Adapter]
    * [Redis Storage Adapter]
    * [Write an Adapter]
  * [Exceptions]
    * [Irreversible Migrations]
    * [Migration not Found]
  * [Using the CLI]

## Installation

Installation is available via [npm] or [github].

```bash
$ npm install boco-migrate
$ git clone https://github.com/bocodigitalmedia/boco-migrate
```

## Usage

```coffee
BocoMigrate = require "boco-migrate"
lastMigration = null

# Create a migrator
migrator = new BocoMigrate.Migrator
  storageAdapter: new BocoMigrate.StorageAdapter

# Add migrations, in order
migrator.addMigration
  id: "migration1"
  up: (done) -> lastMigration = @id; done()
  down: (done) -> lastMigration = null; done()

migrator.addMigration
  id: "migration2"
  up: (done) -> lastMigration = @id; done()
  down: (done) -> lastMigration = "migration1"; done()

migrator.addMigration
  id: "migration3"
  up: (done) -> lastMigration = @id; done()
  down: (done) -> lastMigration = "migration2"; done()
```

### Migrating

passing `null` or `undefined` runs all pending migrations.

```coffee
migrator.migrate null, (error) ->
  throw error if error?
  expect(lastMigration).toEqual "migration3"
  ok()
```

passing a target `migrationId` migrates to the state of that migration.

```coffee
migrator.migrate "migration1", (error) ->
  throw error if error?
  expect(lastMigration).toEqual "migration1"
  ok()
```

### Rolling Back

`rollback` rolls back the latest migration.

```coffee
migrator.migrate null, (error) ->
  throw error if error?

  migrator.rollback (error) ->
    throw error if error?
    expect(lastMigration).toEqual "migration2"
    ok()
```

### Resetting

`reset` rolls back all migrations.

```coffee
migrator.migrate null, (error) ->
  throw error if error?

  migrator.reset (error) ->
    throw error if error?
    expect(lastMigration).toEqual null
    ok()
```

### Storage Adapters

In order for the migrator to persist its state, you must provide it with an adapter for the storage mechanism of your choice.

The default `StorageAdapter` is non-persistent, and thus is primarily used only for testing or as the parent class for other adapters.

#### File Storage Adapter

The `BocoMigrate.FileStorageAdapter` writes data to the JSON file specified by the `path` provided.

```coffee
adapter = new BocoMigrate.FileStorageAdapter
  path: "migratorStorage.json"

migrator.setStorageAdapter adapter

migrator.migrate null, (error) ->
  throw error if error?
  adapter.getLatestMigrationId (error, id) ->
    throw error if error?
    expect(id).toEqual "migration3"
    ok()
```

#### Redis Storage Adapter

The `BocoMigrate.RedisStorageAdapter` writes data to a `redis` instance.

```coffee
redisClient = require("redis").createClient()

adapter = new BocoMigrate.RedisStorageAdapter
  redisClient: redisClient
  keyPrefix: "migrator"
  keyJoinString: "_"

migrator.setStorageAdapter adapter

migrator.migrate null, (error) ->
  throw error if error?
  adapter.getLatestMigrationId (error, id) ->
    throw error if error?
    expect(id).toEqual "migration3"
    ok()
```

#### Writing an Adapter

If you do not see an adapter you need, just subclass the `StorageAdapter` class and modify it to suit the needs of your storage mechanism. If you end up writing an adapter, please [create an issue for your adapter] on this repository's github page.


### Exceptions

#### Irreversible Migrations

A migration that has not defined a `down` method will raise an `IrreversibleMigration` error.

```coffee
migrator.addMigration
  id: "migration4"
  up: (done) -> lastMigration = @id; done()
```

A migration that has not defined a `down` method will raise an `IrreversibleMigration` error.

```coffee
migrator.migrate null, (error) ->
  throw error if error?
  migrator.rollback (error) ->
    expect(error.constructor).toEqual BocoMigrate.IrreversibleMigration
    ok()
```

#### Migration not Found

If you pass an id to `migrate` that is not found, it will raise a `MigrationNotFound` error.

```coffee
migrator.migrate "i dont exist", (error) ->
  expect(error.constructor).toEqual BocoMigrate.MigrationNotFound
  ok()
```

### Using the CLI

A CLI is provided with this package to allow you to run your migrations from the command line.

```text
Usage: boco-migrate <options...> <command>

options:
  -h, --help                   show this help screen
  -e, --example                show an example migrator factory
  -f, --factory=factory_path   path to the migrator factory
                               defaults to "migratorFactory.js"

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
```

#### Creating a Migrator Factory

Your migrator factory file must export a single async function, and returns a `Migrator` instance. This allows you to connect to databases and perform other asynchronous tasks to initialize both the migrator as well as your migrations.

```js
// file: "migratorFactory.js"
var MyDBLib = require("my-db-lib");
var MyDBAdapter = require("my-db-adapter");
var MyDBMigrations = require("my-db-migrations");
var Migrator = require("boco-migrate").Migrator;

module.exports = function(done) {

  MyDBLib.connect(function(error, db) {
    var adapter = new MyDBAdapter({ db: db });
    var migrator = new Migrator({ adapter: adapter });
    var migrations = MyDBMigrations.configure({ db: db });

    migrations.forEach(function(migration) {
      migrator.addMigration(migration);
    });

    return done(null, migrator);
};
```

[Installation]: #installation

[Usage]: #usage
[Migrating]: #migrating
[Rolling Back]: #rolling-back
[Resetting]: #resetting

[Storage Adapters]: #storage-adapters
[File Storage Adapter]: #file-storage-adapter
[Redis Storage Adapter]: #redis-storage-adapter
[Write an Adapter]: #write-an-adapter
[create an issue for your adapter]: https://github.com/bocodigitalmedia/boco-migrate/issues/new?title=Storage%20Adapter%20for:%20MyStorageType&labels=enhancement

[Exceptions]: #exceptions
[Irreversible Migrations]: #irreversible-migrations
[Migration not Found]: #migration-not-found

[Using the CLI]: #using-the-cli
[Creating a Migrator Factory]: #creating-a-migrator-factory

[npm]: http://npmjs.org
[github]: http://www.github.com
