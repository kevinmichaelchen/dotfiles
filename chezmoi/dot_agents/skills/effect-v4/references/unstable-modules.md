# Unstable Modules: SQL, Process, Cluster (Effect v4)

## Table of Contents

- [Child Processes](#child-processes)
- [SQL](#sql)
- [SQL Schema & Resolvers](#sql-schema--resolvers)
- [Cluster & Entities](#cluster--entities)
- [RPC](#rpc)
- [ManagedRuntime](#managedruntime)

## Child Processes

```ts
import { ChildProcess, ChildProcessSpawner } from "effect/unstable/process"
import { NodeChildProcess } from "@effect/platform-node"

// Create a command
const cmd = ChildProcess.make("ls", ["-la"])

// Tagged template literal syntax
const cmd = ChildProcess.make`echo "hello world"`
const cmd = ChildProcess.make`git status`

// With options
const cmd = ChildProcess.make("node", ["script.js"], {
  cwd: "/path/to/dir",
  env: { NODE_ENV: "production" },
  extendEnv: true,         // inherit parent env
  timeout: "30 seconds",   // kill after timeout
  stdin: "pipe",           // "inherit" | "pipe" | "ignore"
  stdout: "pipe",
  stderr: "pipe"
})

// Access the spawner service
const spawner = yield* ChildProcessSpawner.ChildProcessSpawner

// Run and capture output as string
const output = yield* spawner.string(cmd)

// Run and capture output as lines
const lines = yield* spawner.lines(cmd)

// Stream output line by line
const stream = spawner.streamLines(cmd)

// Spawn as a running process handle
const handle = yield* spawner.spawn(cmd)
yield* Stream.runForEach(handle.stdout.pipe(Stream.decodeText(), Stream.splitLines),
  (line) => Effect.log(line)
)
const exitCode = yield* handle.exitCode
yield* handle.kill()

// Pipe commands together
const pipeline = ChildProcess.make("cat", ["package.json"]).pipe(
  ChildProcess.pipeTo(ChildProcess.make("grep", ["name"]))
)
const output = yield* spawner.string(pipeline)

// Provide the platform layer
program.pipe(Effect.provide(NodeChildProcess.layer))
```

## SQL

```ts
import { SqlClient } from "effect/unstable/sql"

// Tagged template literal queries
const sql = yield* SqlClient.SqlClient
const users = yield* sql`SELECT * FROM users WHERE active = ${true}`

// Insert helper
yield* sql`INSERT INTO users ${sql.insert({ name: "Alice", email: "alice@example.com" })}`

// Insert with RETURNING
yield* sql`INSERT INTO users ${sql.insert(userData).returning("*")}`

// Update helper
yield* sql`UPDATE users SET ${sql.update({ name: "Bob" }, ["id"])} WHERE id = ${id}`

// Transactions
yield* sql.withTransaction(
  Effect.gen(function*() {
    yield* sql`INSERT INTO orders (user_id) VALUES (${userId})`
    yield* sql`UPDATE inventory SET stock = stock - 1 WHERE id = ${itemId}`
  })
)

// Platform-specific client
import { PgClient } from "@effect/sql-pg"
const SqlClientLayer = PgClient.layerConfig({
  url: Config.redacted("DATABASE_URL")
})
```

## SQL Schema & Resolvers

Schema-validated queries and request batching:

```ts
import { SqlModel, SqlResolver, SqlSchema } from "effect/unstable/sql"

// Schema-validated queries
const findAll = SqlSchema.findAll({
  Request: Schema.Struct({ active: Schema.Boolean }),
  Result: User,
  execute: (req) => sql`SELECT * FROM users WHERE active = ${req.active}`
})

SqlSchema.findOne(...)         // expects exactly one result
SqlSchema.findOneOption(...)   // returns Option<Result>
SqlSchema.void(...)            // discard result

// Request batching with SqlResolver
const userResolver = SqlResolver.ordered({
  Request: Schema.Struct({ id: Schema.Number }),
  Result: User,
  execute: (requests) => sql`SELECT * FROM users WHERE id IN (${requests.map((r) => r.id)})`
})

// Auto-generated CRUD repository
const UserRepo = yield* SqlModel.makeRepository(User, {
  tableName: "users",
  spanPrefix: "UserRepo",
  idColumn: "id"
})
yield* UserRepo.insert({ name: "Alice", email: "alice@example.com" })
yield* UserRepo.findById(userId)
yield* UserRepo.update({ id: userId, name: "Bob" })
yield* UserRepo.delete(userId)
```

## Cluster & Entities

Distributed entities with location-transparent RPC:

```ts
import { ClusterSchema, Entity, Rpc } from "effect/unstable/cluster"

// Define an RPC
const increment = Rpc.make("increment", {
  payload: Schema.Struct({ amount: Schema.Number }),
  success: Schema.Number,
  error: Schema.Never
})

// Define an entity
const Counter = Entity.make("Counter", {
  rpcs: [increment],
  persistence: ClusterSchema.Persisted
})

// Implement the entity
const CounterLayer = Counter.toLayer(
  Effect.gen(function*() {
    let count = 0
    return {
      increment: Effect.fn(function*({ amount }) {
        count += amount
        return count
      })
    }
  })
)

// Call the entity (location-transparent)
const result = yield* Counter.client("counter-1").increment({ amount: 5 })
```

## RPC

Standalone RPC (without entities):

```ts
import { Rpc, RpcGroup, RpcServer } from "effect/unstable/rpc"

// Define RPCs
const getUser = Rpc.make("getUser", {
  payload: Schema.Struct({ id: Schema.Number }),
  success: User,
  error: UserNotFound
})

// Group RPCs
class UserRpcs extends RpcGroup.make(getUser) {}

// Implement server
const UserRpcServer = RpcServer.layer(UserRpcs, {
  getUser: Effect.fn(function*({ id }) {
    return yield* Users.getById(id)
  })
})
```

## ManagedRuntime

For integrating Effect with non-Effect frameworks (e.g., Hono, Express):

```ts
import { ManagedRuntime } from "effect"

// Create a managed runtime with your layers
const runtime = ManagedRuntime.make(
  Layer.mergeAll(Database.layer, Users.layer)
)

// Use in a Hono handler
app.get("/users/:id", async (c) => {
  const id = c.req.param("id")
  const user = await runtime.runPromise(
    Users.use((users) => users.getById(Number(id)))
  )
  return c.json(user)
})

// Cleanup on shutdown
process.on("SIGTERM", () => runtime.dispose())
```
