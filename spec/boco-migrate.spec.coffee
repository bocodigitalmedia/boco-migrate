$files = {}

describe "boco-migrate", ->

  describe "Usage", ->
    [BocoMigrate, lastMigration, migrator, done] = []

    beforeEach ->
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

    describe "Migrating", ->

      it "passing `null` or `undefined` runs all pending migrations.", (ok) ->
        migrator.migrate null, (error) ->
          throw error if error?
          expect(lastMigration).toEqual "migration3"
          ok()

      it "passing a target `migrationId` migrates to the state of that migration.", (ok) ->
        migrator.migrate "migration1", (error) ->
          throw error if error?
          expect(lastMigration).toEqual "migration1"
          ok()

    describe "Rolling Back", ->

      it "`rollback` rolls back the latest migration.", (ok) ->
        migrator.migrate null, (error) ->
          throw error if error?
        
          migrator.rollback (error) ->
            throw error if error?
            expect(lastMigration).toEqual "migration2"
            ok()

    describe "Resetting", ->

      it "`reset` rolls back all migrations.", (ok) ->
        migrator.migrate null, (error) ->
          throw error if error?
        
          migrator.reset (error) ->
            throw error if error?
            expect(lastMigration).toEqual null
            ok()

    describe "Storage Adapters", ->
      [testAdapter, adapter, resetAdapter, testMigrate, testReset, series] = []

      beforeEach ->
        testAdapter = null
        
        testAdapter = (adapter, done) ->
          migrator.setStorageAdapter adapter
        
          resetAdapter = (done) -> adapter.reset done
          testMigrate = (done) -> migrator.migrate null, done
          testReset = (done) -> migrator.reset done
        
          series = [resetAdapter, testMigrate, testReset]
          require("async").series series, done

      describe "File Storage Adapter", ->

        it "The `BocoMigrate.FileStorageAdapter` writes data to the JSON file specified by the `path` provided.", (ok) ->
          adapter = new BocoMigrate.FileStorageAdapter
            path: "migratorStorage.json"
          
          testAdapter adapter, (error) ->
            expect(error?).toEqual false
            ok()

      describe "Redis Storage Adapter", ->

        it "The `BocoMigrate.RedisStorageAdapter` writes data to a `redis` instance.", (ok) ->
          redisClient = require("redis").createClient()
          
          adapter = new BocoMigrate.RedisStorageAdapter
            redisClient: redisClient
            keyPrefix: "migrator"
            keyJoinString: "_"
          
          testAdapter adapter, (error) ->
            expect(error?).toEqual false
            ok()

    describe "Exceptions", ->

      describe "Irreversible Migrations", ->

        beforeEach ->
          migrator.addMigration
            id: "migration4"
            up: (done) -> lastMigration = @id; done()

        it "A migration that has not defined a `down` method will raise an `IrreversibleMigration` error.", (ok) ->
          migrator.migrate null, (error) ->
            throw error if error?
            migrator.rollback (error) ->
              expect(error.constructor).toEqual BocoMigrate.IrreversibleMigration
              ok()

      describe "Migration not Found", ->

        it "If you pass an id to `migrate` that is not found, it will raise a `MigrationNotFound` error.", (ok) ->
          migrator.migrate "i dont exist", (error) ->
            expect(error.constructor).toEqual BocoMigrate.MigrationNotFound
            ok()
