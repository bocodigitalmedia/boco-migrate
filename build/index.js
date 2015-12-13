// Generated by CoffeeScript 1.10.0
var configure,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty,
  slice = [].slice;

configure = function($) {
  var $async, $lodash, $minimist, $path, $process, BocoMigrate, CLI, IdentityNotUnique, IrreversibleMigration, MigrateError, Migration, MigrationNotFound, Migrator, NotImplemented, StorageAdapter, ref, ref1, ref2, ref3, ref4;
  if ($ == null) {
    $ = {};
  }
  $async = (ref = $.async) != null ? ref : require("async");
  $lodash = (ref1 = $.lodash) != null ? ref1 : require("lodash");
  $minimist = (ref2 = $.minimist) != null ? ref2 : require("minimist");
  $process = (ref3 = $.process) != null ? ref3 : process;
  $path = (ref4 = $.path) != null ? ref4 : require("path");
  MigrateError = (function(superClass) {
    extend(MigrateError, superClass);

    function MigrateError(props) {
      var key, val;
      for (key in props) {
        if (!hasProp.call(props, key)) continue;
        val = props[key];
        this[key] = val;
      }
      Error.captureStackTrace(this, this.constructor);
      if (this.name == null) {
        this.name = this.constructor.name;
      }
    }

    return MigrateError;

  })(Error);
  IdentityNotUnique = (function(superClass) {
    extend(IdentityNotUnique, superClass);

    function IdentityNotUnique() {
      return IdentityNotUnique.__super__.constructor.apply(this, arguments);
    }

    IdentityNotUnique.prototype.message = "Identity not unique";

    return IdentityNotUnique;

  })(MigrateError);
  MigrationNotFound = (function(superClass) {
    extend(MigrationNotFound, superClass);

    function MigrationNotFound() {
      return MigrationNotFound.__super__.constructor.apply(this, arguments);
    }

    MigrationNotFound.prototype.message = "Migration not found";

    return MigrationNotFound;

  })(MigrateError);
  IrreversibleMigration = (function(superClass) {
    extend(IrreversibleMigration, superClass);

    function IrreversibleMigration() {
      return IrreversibleMigration.__super__.constructor.apply(this, arguments);
    }

    IrreversibleMigration.prototype.message = "Irreversible Migration";

    return IrreversibleMigration;

  })(MigrateError);
  NotImplemented = (function(superClass) {
    extend(NotImplemented, superClass);

    function NotImplemented() {
      return NotImplemented.__super__.constructor.apply(this, arguments);
    }

    NotImplemented.prototype.message = "Not implemented";

    return NotImplemented;

  })(MigrateError);
  Migration = (function() {
    Migration.prototype.id = null;

    function Migration(props) {
      var key, val;
      for (key in props) {
        if (!hasProp.call(props, key)) continue;
        val = props[key];
        this[key] = val;
      }
    }

    Migration.prototype.up = function(done) {
      return done(new NotImplemented);
    };

    Migration.prototype.down = function(done) {
      return done(new IrreversibleMigration);
    };

    return Migration;

  })();
  StorageAdapter = (function() {
    StorageAdapter.prototype.latestMigrationId = null;

    function StorageAdapter(props) {
      var key, val;
      for (key in props) {
        if (!hasProp.call(props, key)) continue;
        val = props[key];
        this[key] = val;
      }
    }

    StorageAdapter.prototype.setLatestMigrationId = function(id, done) {
      return done(null, (this.latestMigrationId = id));
    };

    StorageAdapter.prototype.getLatestMigrationId = function(done) {
      return done(null, this.latestMigrationId);
    };

    return StorageAdapter;

  })();
  Migrator = (function() {
    Migrator.prototype.migrations = null;

    Migrator.prototype.storageAdapter = null;

    function Migrator(props) {
      var key, val;
      for (key in props) {
        if (!hasProp.call(props, key)) continue;
        val = props[key];
        this[key] = val;
      }
      if (this.migrations == null) {
        this.migrations = [];
      }
      if (this.storageAdapter == null) {
        this.storageAdapter = new StorageAdapter;
      }
    }

    Migrator.prototype.addMigration = function(migration) {
      if (!(migration instanceof Migration)) {
        migration = new Migration(migration);
      }
      this.migrations.push(migration);
      return migration;
    };

    Migrator.prototype.findMigrationById = function(id) {
      var index;
      index = this.findMigrationIndexById(id);
      return this.migrations[index];
    };

    Migrator.prototype.findMigrationIndexById = function(id) {
      var index;
      index = $lodash.findIndex(this.migrations, function(migration) {
        return migration.id === id;
      });
      if (!((index != null) && index > -1)) {
        throw new MigrationNotFound;
      }
      return index;
    };

    Migrator.prototype.migrate = function(targetId, done) {
      return this.storageAdapter.getLatestMigrationId((function(_this) {
        return function(error, latestId) {
          var latestIndex, migrations, startIndex, targetIndex;
          if (error != null) {
            return done(error);
          }
          if (latestId != null) {
            latestIndex = _this.findMigrationIndexById(latestId);
          }
          if (targetId != null) {
            targetIndex = _this.findMigrationIndexById(targetId);
          }
          if (latestIndex == null) {
            latestIndex = -1;
          }
          if (targetIndex == null) {
            targetIndex = _this.migrations.length - 1;
          }
          if (targetIndex === latestIndex) {
            return done();
          }
          if (targetIndex > latestIndex) {
            startIndex = latestIndex + 1;
            migrations = _this.migrations.slice(startIndex, targetIndex + 1);
            return _this.runUpMigrations(migrations, done);
          }
          if (targetIndex < latestIndex) {
            startIndex = targetIndex + 1;
            migrations = _this.migrations.slice(startIndex, latestIndex + 1).reverse();
            return _this.runDownMigrations(migrations, done);
          }
        };
      })(this));
    };

    Migrator.prototype.rollback = function(done) {
      return this.storageAdapter.getLatestMigrationId((function(_this) {
        return function(error, latestId) {
          var latestMigration;
          if (latestId == null) {
            return done();
          }
          latestMigration = _this.findMigrationById(latestId);
          return _this.runDownMigration(latestMigration, done);
        };
      })(this));
    };

    Migrator.prototype.runUpMigration = function(migration, done) {
      return migration.up((function(_this) {
        return function(error) {
          if (error != null) {
            return done(error);
          }
          return _this.storageAdapter.setLatestMigrationId(migration.id, done);
        };
      })(this));
    };

    Migrator.prototype.runUpMigrations = function(migrations, done) {
      return $async.eachSeries(migrations, this.runUpMigration.bind(this), done);
    };

    Migrator.prototype.runDownMigration = function(migration, done) {
      return migration.down((function(_this) {
        return function(error) {
          var index, latestMigration;
          if (error != null) {
            return done(error);
          }
          index = _this.findMigrationIndexById(migration.id);
          latestMigration = _this.migrations[index - 1];
          return _this.storageAdapter.setLatestMigrationId(latestMigration != null ? latestMigration.id : void 0, done);
        };
      })(this));
    };

    Migrator.prototype.runDownMigrations = function(migrations, done) {
      return $async.eachSeries(migrations, this.runDownMigration.bind(this), done);
    };

    return Migrator;

  })();
  CLI = (function() {
    function CLI() {}

    CLI.prototype.getHelp = function() {
      var cmd;
      cmd = $path.basename($process.argv[1]);
      return "Usage: " + cmd + " <options...> <command>\n\noptions:\n  --help                      show this help screen\n  --factory=factory_path.js   path to your migrator factory\n\ncommands:\n  migrate <target_migration_id>\n    Migrate to the (optional) target migration id\n  rollback\n    Roll back the previous migration\n  example\n    Print an example factory.js\n\nfactory:\n  A javascript file that exports a single async factory method,\n  returning a migrator instance for the CLI.";
    };

    CLI.prototype.showHelp = function(code) {
      if (code == null) {
        code = 0;
      }
      $process.stdout.write(this.getHelp() + "\n");
      return $process.exit(code);
    };

    CLI.prototype.getExample = function() {
      return "// example factory.js\nmodule.exports = function(done) {\n  require(\"my-database-lib\").connect(function(error, connection) {\n    if(error != null) { return done(error); }\n\n    var BocoMigrate = require(\"boco-migrate\");\n    var MyStorageAdapter = require(\"my-database-storage-adapter\");\n\n    var storageAdapter = new MyStorageAdapter({\n      connection: connection\n    });\n\n    var migrator = new BocoMigrate.Migrator({\n      storageAdapter: storageAdapter\n    });\n\n    var migrations = require(\"./migrations\").configure({\n      connection: connection\n    });\n\n    migrator.addMigrations(migrations);\n    return done(null, migrator);\n  });\n};";
    };

    CLI.prototype.example = function() {
      return $process.stdout.write(this.getExample() + "\n");
    };

    CLI.prototype.getMigrator = function(factoryPath, done) {
      var path;
      if (factoryPath == null) {
        throw TypeError("missing argument: --factory");
      }
      path = $path.resolve($process.cwd(), factoryPath);
      if (!/^[\\\/]/.test(path)) {
        path = "./" + path;
      }
      return require(path)(done);
    };

    CLI.prototype.migrate = function(factoryPath, targetId) {
      return this.getMigrator(factoryPath, function(error, migrator) {
        if (error != null) {
          throw error;
        }
        return migrator.migrate(targetId, function(error) {
          if (error != null) {
            throw error;
          }
          return process.exit();
        });
      });
    };

    CLI.prototype.rollback = function(factoryPath) {
      return this.getMigrator(factoryPath, function(error, migrator) {
        if (error != null) {
          throw error;
        }
        return migrator.rollback(function(error) {
          if (error != null) {
            throw error;
          }
          return process.exit();
        });
      });
    };

    CLI.prototype.getParams = function() {
      var argv, minimist, params;
      argv = $process.argv.slice(2);
      minimist = $minimist(argv, {
        boolean: ["example", "help"],
        string: ["factory"]
      });
      return params = {
        help: minimist.help,
        example: minimist.example,
        command: minimist._[0],
        factory: minimist.factory,
        args: minimist._.slice(1)
      };
    };

    CLI.prototype.run = function() {
      var params;
      params = this.getParams();
      if (params.help) {
        return this.showHelp();
      }
      switch (params.command) {
        case "migrate":
          return this.migrate.apply(this, [params.factory].concat(slice.call(params.args)));
        case "rollback":
          return this.rollback.apply(this, [params.factory].concat(slice.call(params.args)));
        case "example":
          return this.example.apply(this, params.args);
        default:
          return this.showHelp(1);
      }
    };

    return CLI;

  })();
  return BocoMigrate = {
    MigrateError: MigrateError,
    IrreversibleMigration: IrreversibleMigration,
    NotImplemented: NotImplemented,
    MigrationNotFound: MigrationNotFound,
    Migration: Migration,
    StorageAdapter: StorageAdapter,
    Migrator: Migrator,
    CLI: CLI
  };
};

module.exports = configure();

//# sourceMappingURL=index.js.map
