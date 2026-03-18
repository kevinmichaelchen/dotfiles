# Config & ConfigProvider (Effect v4)

## Table of Contents

- [Reading Config Values](#reading-config-values)
- [Config Types](#config-types)
- [Config Composition](#config-composition)
- [Schema-Based Config](#schema-based-config)
- [Config in Layers](#config-in-layers)
- [ConfigProvider](#configprovider)

## Reading Config Values

```ts
import { Config, Effect } from "effect"

const program = Effect.gen(function*() {
  const port = yield* Config.number("PORT")
  const host = yield* Config.string("HOST")
  const debug = yield* Config.boolean("DEBUG").pipe(Config.withDefault(false))
  yield* Effect.log(`Listening on ${host}:${port}`)
})
```

## Config Types

```ts
Config.string("KEY")               // string
Config.nonEmptyString("KEY")       // rejects empty strings
Config.number("KEY")               // number (includes NaN/Infinity)
Config.finite("KEY")               // number (rejects NaN/Infinity)
Config.int("KEY")                  // integer only
Config.boolean("KEY")              // parses: true/false, yes/no, on/off, 1/0, y/n
Config.date("KEY")                 // ISO date string → Date
Config.port("KEY")                 // integer 1-65535
Config.duration("KEY")             // "10 seconds", "500 millis", "2 minutes"
Config.logLevel("KEY")             // "All", "Fatal", "Error", "Warn", "Info", "Debug", "Trace", "None"
Config.redacted("KEY")             // Redacted<string> (hides from logs)
Config.url("KEY")                  // URL string → URL object
Config.literal("production", "ENV")   // exact literal match (single value)
```

## Config Composition

```ts
// Optional with default (only for MISSING data, not validation errors)
Config.string("LOG_LEVEL").pipe(Config.withDefault("info"))

// Optional as Option (Some on value, None on missing)
Config.number("PORT").pipe(Config.option)

// Fallback on ANY error (missing + validation)
Config.number("PORT").pipe(
  Config.orElse(() => Config.succeed(3000))
)

// Nested config (reads DB_HOST, DB_PORT, etc.)
const dbConfig = Config.all({
  host: Config.string("HOST"),
  port: Config.number("PORT"),
  name: Config.string("NAME")
}).pipe(Config.nested("DB"))

// Map/transform
Config.string("PORT").pipe(Config.map(Number))

// Validation via mapOrFail
Config.string("ENV").pipe(
  Config.mapOrFail((s) =>
    ["dev", "staging", "prod"].includes(s)
      ? Effect.succeed(s)
      : Effect.fail(new Config.Error({ message: "Must be dev, staging, or prod" }))
  )
)
```

**Gotcha**: `withDefault` and `option` only catch missing-data errors. Validation errors still propagate. Use `orElse` to catch both.

## Schema-Based Config

```ts
// Struct config from Schema
const dbConfig = Config.schema(
  Schema.Struct({
    host: Schema.String,
    port: Schema.Int,
    replicas: Schema.Array(Schema.String)
  }),
  "database"  // optional prefix path
)

// Record from comma-separated string
const config = Config.schema(
  Config.Record(Schema.String, Schema.String),
  "OTEL_RESOURCE_ATTRIBUTES"
)
// "service.name=my-service,version=1.0.0" → { "service.name": "my-service", "version": "1.0.0" }

// Custom separators
Config.Record(Schema.String, Schema.String, {
  separator: "&",
  keyValueSeparator: "=="
})
```

## Config in Layers

```ts
// Layer.unwrap for config-driven layer selection
static readonly layer = Layer.unwrap(
  Effect.gen(function*() {
    const useLocal = yield* Config.boolean("USE_LOCAL").pipe(Config.withDefault(false))
    return useLocal ? MyService.layerLocal : MyService.layerRemote
  })
)

// Config in Layer.effect
static readonly layer = Layer.effect(
  Database,
  Effect.gen(function*() {
    const url = yield* Config.string("DATABASE_URL")
    const pool = yield* makePool(url)
    return Database.of({ pool })
  })
)
```

## ConfigProvider

```ts
import { ConfigProvider, Layer } from "effect"

// From environment variables (default)
ConfigProvider.fromEnv()
// Path segments joined with "_": ["DATABASE", "HOST"] → DATABASE_HOST

// From JSON object (for testing)
ConfigProvider.fromUnknown({ HOST: "localhost", PORT: "3000" })

// From .env file contents
ConfigProvider.fromDotEnvContents(envString, { expandVariables: true })

// From .env file (requires FileSystem service)
const provider = yield* ConfigProvider.fromDotEnv({ path: ".env" })

// From directory tree (Kubernetes ConfigMap/Secret mounts)
const provider = yield* ConfigProvider.fromDir({ rootPath: "/etc/secrets" })

// Override config provider for testing
const TestConfig = ConfigProvider.layer(
  ConfigProvider.fromUnknown({
    HOST: "localhost",
    PORT: "3000",
    DB_HOST: "localhost",
    DB_PORT: "5432"
  })
)
program.pipe(Effect.provide(TestConfig))

// Add fallback provider without replacing existing
ConfigProvider.layerAdd(
  ConfigProvider.fromUnknown(defaults),
  { asPrimary: false }  // existing provider is primary, this is fallback
)

// Compose providers (fallback chain)
ConfigProvider.fromEnv().pipe(
  ConfigProvider.orElse(ConfigProvider.fromUnknown(defaults))
)

// Transform path segments (camelCase → CONSTANT_CASE)
ConfigProvider.fromEnv().pipe(ConfigProvider.constantCase)
```
