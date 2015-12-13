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

## Using the CLI

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

### Creating a Migrator Factory

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

---

Copyright (c) 2015 Christian Bradley + Boco Digital Media, LLC

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
