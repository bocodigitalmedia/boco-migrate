## Usage

* [Define a State Store](#define-a-state-store)
* [Create a Migrator](#create-a-migrator)
* [Create Migrations](#create-migrations)
* [Add Migrations](#add-migrations)
* [Migrating up to the Latest Version](#migrating-to-the-latest-version)
* [Migrating to a Specific Version](#migrating-down-to-a-specific-version)

### Define a State Store

The migrator needs to save and retrieve state information to determine which migrations to run.
This information should be stored on a filesystem, database, or key-value store.

For these examples, we will use the built-in `MemoryStateStore`.
Note that this should only be used for testing, as it is non-persistent.

```coffee

stateStore = new BocoMigrate.MemoryStateStore

```

See [State Stores](#state-stores) for more information.

### Create a Migrator

Configure the migrator with the state store you created.

```coffee

migrator = new BocoMigrate.Migrator stateStore: stateStore

```

### Create Migrations

A migration must have an unique `name` and `timestamp`, and an `up` method.

If you do not specify a `down` method, it will be considered an irreversable migration.

Let's create some migrations that add messages to an array, so we can observe what happens
when we run them.

```coffee

messages = []

```

You can create a migration as an instance of `Migration`.

```coffee

migration1 = new BocoMigrate.Migration
  name: "migration1"
  timestamp: "2015-01-01T00:00:00Z"
  up: (done) -> messages.push "message from #{@name}"; done()
  down: (done) -> messages.pop(); done()

```

You can also create custom classes for your migrations, extending `Migration`.

```coffee

class AddMessage extends BocoMigrate.Migration
  constructor: (name, timestamp, messages) ->
    super name: name, timestamp: timestamp
    @messages = messages

  up: (done) -> @messages.push "message from #{@name}"; done()
  down: (done) -> @messages.pop(); done()

migration2 = new AddMessage "migration2", "2015-01-02T01:30:00Z", messages
migration3 = new AddMessage "migration3", "2015-03-25T22:15:33Z", messages

```

### Add Migrations

```coffee

migrator.addMigrations migration1, migration2, migration3

```

### Migrating Up To The Latest Version

```coffee

test "migrating to the latest version", (done) ->

  migrator.migrate (error) ->
    return done error if error?
    assert.equal 3, messages.length
    assert.equal "message from migration3", messages[2]
    done()

```

### Migrating to a Specific Version

```coffee

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

```
