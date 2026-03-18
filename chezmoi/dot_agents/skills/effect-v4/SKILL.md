---
name: effect-v4
description: "Write idiomatic Effect v4 (TypeScript) code. Use when writing, reviewing, or refactoring code that uses the Effect library (imports from \"effect\"), including Effect.gen, Effect.fn, ServiceMap.Service, Layer, Schema, HttpApi, Stream, Config, Match, Optic, Data.TaggedEnum, Logger, Metric, Tracer, DateTime, Pool, Cache, CLI (Command/Flag), AI (LanguageModel/Tool/Chat), SQL, Cluster, RPC, ChildProcess, error handling with TaggedErrorClass, and testing with @effect/vitest. Covers services, dependency injection, resource management, concurrency, HTTP APIs, observability, pattern matching, and all core Effect patterns."
---

# Writing Idiomatic Effect v4 Code

## Core Patterns

### Effect.gen for imperative-style Effect code

```ts
import { Effect } from "effect"

Effect.gen(function*() {
  yield* Effect.log("Starting...")
  const result = yield* someEffect
  // Always `return yield*` when raising errors to stop execution
  return yield* new MyError({ message: "failed" })
})
```

### Effect.fn for functions returning Effects

**Never** write functions that return `Effect.gen`. Use `Effect.fn` instead.

```ts
// Pass a name string for tracing spans and stack traces
export const myFunction = Effect.fn("myFunction")(
  function*(input: string): Effect.fn.Return<number, MyError> {
    yield* Effect.logInfo("processing", input)
    return input.length
  },
  // Post-processing combinators go here, NOT in .pipe()
  Effect.catch((e) => Effect.succeed(0)),
  Effect.annotateLogs({ fn: "myFunction" })
)
```

For **internal helpers** that don't need tracing, use `Effect.fnUntraced`:

```ts
const helper = Effect.fnUntraced(function*(x: number) {
  return x + 1
})
```

### Creating Effects from various sources

```ts
Effect.succeed(value)                        // already in memory
Effect.sync(() => Date.now())                // sync side effect, won't throw
Effect.try({ try: () => JSON.parse(s), catch: (cause) => new ParseError({ cause }) })
Effect.tryPromise({ try: () => fetch(url), catch: (cause) => new FetchError({ cause }) })
Effect.fromNullishOr(nullableValue)          // nullable -> Effect
Effect.callback<T>((resume) => { ... })      // callback APIs
```

## Services & Dependency Injection

### Defining services with ServiceMap.Service

Use the class pattern. First type parameter is `Self`, second is the service interface.

```ts
// file: src/db/Database.ts
import { Effect, Layer, Schema, ServiceMap } from "effect"

export class Database extends ServiceMap.Service<Database, {
  query(sql: string): Effect.Effect<Array<unknown>, DatabaseError>
}>()("myapp/db/Database") {
  // Attach a static layer
  static readonly layer = Layer.effect(
    Database,
    Effect.gen(function*() {
      const query = Effect.fn("Database.query")(function*(sql: string) {
        yield* Effect.log("Executing:", sql)
        return [{ id: 1 }]
      })
      return Database.of({ query })
    })
  )
}

export class DatabaseError extends Schema.TaggedErrorClass<DatabaseError>()("DatabaseError", {
  cause: Schema.Defect
}) {}
```

The string identifier should include package/path: `"myapp/db/Database"`.

### Accessing services

Services are yieldable:

```ts
const program = Effect.gen(function*() {
  const db = yield* Database
  const results = yield* db.query("SELECT * FROM users")
})
```

Or use `.use`:

```ts
Database.use((db) => db.query("SELECT 1"))
```

### ServiceMap.Reference for config/feature flags

```ts
export const FeatureFlag = ServiceMap.Reference<boolean>("myapp/FeatureFlag", {
  defaultValue: () => false
})
```

## Layers

### Constructing layers

```ts
Layer.succeed(Service)(implementation)        // sync, already have the value
Layer.sync(Service)(() => implementation)     // lazy sync
Layer.effect(Service, effectThatBuildsIt)     // effectful construction
Layer.effectDiscard(sideEffectOnly)           // no service, just side effects
```

### Composing layers

```ts
// Layer.provide: satisfy dependencies, expose only the outer service
static readonly layer = this.layerNoDeps.pipe(
  Layer.provide(DependencyService.layer)
)

// Layer.provideMerge: satisfy deps AND expose the dependency too
static readonly layerWithDeps = this.layerNoDeps.pipe(
  Layer.provideMerge(DependencyService.layer)
)

// Layer.merge: combine independent layers
const combined = Layer.mergeAll(LayerA, LayerB, LayerC)
```

### Dynamic resources with LayerMap

```ts
class PoolMap extends LayerMap.Service<PoolMap>()("app/PoolMap", {
  lookup: (tenantId: string) => DatabasePool.layer(tenantId),
  idleTimeToLive: "1 minute"
}) {}

// Usage
yield* query.pipe(Effect.provide(PoolMap.get("acme")))
```

### Layer.unwrap for config-driven layers

```ts
static readonly layer = Layer.unwrap(
  Effect.gen(function*() {
    const useLocal = yield* Config.boolean("USE_LOCAL").pipe(Config.withDefault(false))
    return useLocal ? MyService.layerLocal : MyService.layerRemote
  })
)
```

## Error Handling

### Define errors with Schema.TaggedErrorClass

```ts
export class NotFoundError extends Schema.TaggedErrorClass<NotFoundError>()(
  "NotFoundError",
  { id: Schema.String },
  // Optional: HTTP status for HttpApi
  { httpApiStatus: 404 }
) {}
```

For errors without schema fields, use `Schema.TaggedErrorClass<T>()("Tag", {})`.

For non-tagged errors: `Schema.ErrorClass<T>("Tag")({ ... })`.

### Wrapper errors with reasons

Group related errors under one parent with a `reason` field:

```ts
export class UsersError extends Schema.TaggedErrorClass<UsersError>()("UsersError", {
  reason: Schema.Union([UserNotFound, SearchQueryTooShort])
}) {}
```

### Raising errors in generators

**Always** use `return yield*` when raising errors:

```ts
Effect.gen(function*() {
  const user = users.get(id)
  if (user === undefined) {
    return yield* new UserNotFound({ id })
  }
  return user
})
```

### Catching errors

```ts
// Catch all errors
Effect.catch((error) => Effect.succeed(fallback))

// Catch by tag
Effect.catchTag("NotFoundError", (e) => Effect.succeed(null))

// Catch multiple tags at once
Effect.catchTag(["ParseError", "NotFoundError"], (_) => Effect.succeed(fallback))

// Catch with tag map
Effect.catchTags({
  NotFoundError: (e) => Effect.succeed(null),
  ParseError: (e) => Effect.succeed(defaultValue)
})

// Catch specific reason from a wrapper error
Effect.catchReason("UsersError", "UserNotFound", handleFn, catchAllOtherReasons)

// Catch multiple reasons
Effect.catchReasons("UsersError", {
  UserNotFound: (e) => Effect.fail(e),
  SearchQueryTooShort: (e) => Effect.fail(e)
}, Effect.die)  // catch-all for remaining reasons

// Unwrap reasons into the error channel
Effect.unwrapReason("UsersError")
```

### Converting to defects

```ts
Effect.orDie  // all errors become defects (unchecked)
```

## Schema

### Defining data classes

```ts
export class User extends Schema.Class<User>("User")({
  id: UserId,
  name: Schema.String,
  email: Schema.String
}) {}
```

### Branded types

```ts
export const UserId = Schema.Int.pipe(Schema.brand("UserId"))
export type UserId = typeof UserId.Type
```

### Decoding

```ts
Schema.decodeUnknownSync(MySchema)(input)  // throws
Schema.decodeUnknownEffect(MySchema)(input) // Effect
```

## Resource Management

### acquireRelease in a Layer

```ts
static readonly layer = Layer.effect(
  MyService,
  Effect.gen(function*() {
    const resource = yield* Effect.acquireRelease(
      Effect.sync(() => openConnection()),
      (conn) => Effect.sync(() => conn.close())
    )
    return MyService.of({ /* use resource */ })
  })
)
```

### Background tasks in Layers

```ts
const Worker = Layer.effectDiscard(Effect.gen(function*() {
  yield* Effect.gen(function*() {
    while (true) {
      yield* Effect.sleep("5 seconds")
      yield* Effect.logInfo("tick")
    }
  }).pipe(Effect.forkScoped)
}))
```

## Running Programs

```ts
import { NodeRuntime } from "@effect/platform-node"

// Long-running service
Layer.launch(HttpServerLayer).pipe(NodeRuntime.runMain)

// One-shot program
program.pipe(Effect.provide(AppLayer), NodeRuntime.runMain)
```

## HttpApi (Schema-First HTTP)

See [references/http-api.md](references/http-api.md) for complete HttpApi patterns.

Key points:
- API definitions go in separate files from server implementations
- Use `HttpApiGroup.make`, `HttpApiEndpoint.get/post/...`
- Implement handlers with `HttpApiBuilder.group`
- Serve with `HttpRouter.serve`
- Generate typed clients with `HttpApiClient.make`
- HttpApi imports come from `"effect/unstable/httpapi"`
- Http transport imports come from `"effect/unstable/http"`

## Testing

See [references/testing.md](references/testing.md) for complete testing patterns.

Key points:
- Use `{ assert, describe, it } from "@effect/vitest"` (not vitest directly)
- Use `assert` methods, **never** `expect`
- Use `it.effect("desc", () => Effect.gen(function*() { ... }))`
- Use `TestClock` from `"effect/testing"` for time-dependent tests
- Use `layer(...)` for shared test layers
- Use `it.effect.prop` with Schema arbitraries for property-based tests

## Streams, Concurrency & Schedule

See [references/streams-concurrency-schema.md](references/streams-concurrency-schema.md) for Stream creation/consumption, concurrency patterns (Fiber, Ref, Queue, PubSub), Schedule, Request batching, and STM/transactional collections.

## Config & ConfigProvider

See [references/config.md](references/config.md) for reading config values, config types, composition, validation, and ConfigProvider for testing.

## Observability: Logging, Metrics & Tracing

See [references/observability.md](references/observability.md) for logging (Effect.log, structured logging), log levels, annotations, spans, Logger configuration, OTLP tracing, and Metric (counter, gauge, histogram, summary).

## Data Types & Pattern Matching

See [references/data-types.md](references/data-types.md) for Data.TaggedEnum, Data.Class, Data.TaggedClass, Match module (exhaustive pattern matching), Optic module (functional lenses), Option, and Either.

## Utility Modules

See [references/utilities.md](references/utilities.md) for DateTime, Encoding (base64/hex), Redacted (secrets), Pool, Cache, Resource (acquireRelease/scoped), and Duration.

## CLI Module

See [references/cli.md](references/cli.md) for building CLI tools with Command, Flag, Argument, and subcommands. Import from `"effect/unstable/cli"`.

## AI Module

See [references/ai.md](references/ai.md) for LanguageModel (generateText/generateObject), Tool, Toolkit, Chat sessions, and agentic loops. Import from `"effect/unstable/ai"`.

## Unstable Modules: SQL, Process, Cluster

See [references/unstable-modules.md](references/unstable-modules.md) for child processes, SQL queries/transactions, Cluster entities, RPC, and ManagedRuntime integration.

## Anti-Patterns to Avoid

1. **Never** write `(args) => Effect.gen(function*() { ... })`. Use `Effect.fn("name")(function*(args) { ... })`.
2. **Never** use `try-catch` inside `Effect.gen`. Use `Effect.try` / `Effect.tryPromise`.
3. **Never** use type assertions (`as any`, `as never`, `as unknown`).
4. **Never** use `expect` from vitest. Use `assert` from `@effect/vitest`.
5. **Never** use bare `it()` with `Effect.runSync`. Use `it.effect()`.
6. **Never** forget `return` before `yield*` when raising errors in generators.
7. **Never** use `.pipe()` with `Effect.fn` — pass combinators as additional arguments.
8. **Never** use `Data.TaggedError` for new code — use `Schema.TaggedErrorClass`.
9. **Never** manually edit `index.ts` barrel files — run `pnpm codegen`.
