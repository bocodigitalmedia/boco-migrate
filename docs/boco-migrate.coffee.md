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
  * [Irreversible Migrations]
* [Storage Adapters]
  * [Available Adapters]
  * [Write an Adapter]

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

### Irreversible Migrations

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

## Storage Adapters

In order for the migrator to persist its state, you must provide it with a storage adapter for the storage mechanism of your choice.

The default `StorageAdapter` is non-persistent, and primarily used for testing or as a parent class for extended adapters.

### Available Adapters

The `StorageAdapter` interface is currently in flux, and expected to be settled shortly in __v2.0__. Once the interface has been locked down, I will release a few options and list them here.


[Installation]: #installation
[Usage]: #usage
[Migrating]: #migrating
[Rolling Back]: #rolling-back
[Resetting]: #resetting
[Irreversible Migrations]: #irreversible-migrations
[Storage Adapters]: #storage-adapters
[Available Adapters]: #available-adapters
[Write an Adapter]: #write-an-adapter

[npm]: http://npmjs.org
[github]: http://www.github.com
