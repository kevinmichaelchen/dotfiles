# Utility Modules (Effect v4)

## Table of Contents

- [DateTime](#datetime)
- [Encoding](#encoding)
- [Redacted](#redacted)
- [Pool](#pool)
- [Cache](#cache)
- [Resource](#resource)
- [Duration](#duration)

## DateTime

```ts
import { DateTime } from "effect"

// Current time (effectful, works with TestClock)
const now = yield* DateTime.now

// From various inputs (unsafe, throws on invalid)
DateTime.makeUnsafe("2024-01-15T10:30:00Z")
DateTime.makeUnsafe(1705312200000)

// From parts
DateTime.makeUnsafe({ year: 2024, month: 3, day: 15 })

// Formatting
DateTime.formatIso(dt)
DateTime.format(dt, { locale: "en-US", dateStyle: "full", timeStyle: "full" })

// Arithmetic
DateTime.add(dt, { days: 7 })
DateTime.subtract(dt, { hours: 2 })

// Period operations
DateTime.startOf(dt, "month")   // start of month/day/year/week
DateTime.endOf(dt, "month")
DateTime.nearest(dt, "hour")    // round to nearest

// Get/set parts
DateTime.getPartUtc(dt, "year")      // year, month, day, weekDay, etc.
DateTime.setPartsUtc(dt, { month: 6 })

// Comparison
DateTime.isLessThan(a, b)
DateTime.isGreaterThan(a, b)
DateTime.between(dt, { minimum: start, maximum: end })
DateTime.distance(a, b)               // Duration between two dates

// Timezone
const zoned = yield* DateTime.nowInCurrentZone.pipe(
  DateTime.withCurrentZoneNamed("Pacific/Auckland")
)
DateTime.toUtc(zoned)
DateTime.toDate(zoned)
```

## Encoding

```ts
import { Encoding } from "effect"

// Base64
Encoding.encodeBase64("hello")           // "aGVsbG8="
Encoding.decodeBase64String("aGVsbG8=")  // Result<string, EncodingError>

// Base64 URL-safe (uses - and _ instead of + and /)
Encoding.encodeBase64Url("hello?")
Encoding.decodeBase64UrlString(encoded)

// Hex
Encoding.encodeHex("hello")              // "68656c6c6f"
Encoding.decodeHexString(hexStr)

// Decode to bytes
Encoding.decodeBase64("aGVsbG8=")        // Result<Uint8Array, EncodingError>
Encoding.decodeHex(hexStr)               // Result<Uint8Array, EncodingError>
```

All decode functions return `Result` — check with `Result.isSuccess()`.

## Redacted

Secrets that don't leak in logs:

```ts
import { Redacted } from "effect"

const secret = Redacted.make("my-api-key")
console.log(secret)          // Redacted(<redacted>)
console.log(String(secret))  // "<redacted>"
JSON.stringify(secret)       // "\"<redacted>\""

// With label for debugging
const password = Redacted.make("pass", { label: "PASSWORD" })
String(password)             // "<redacted:PASSWORD>"

// Access the value when needed
const value = Redacted.value(secret)  // "my-api-key"

// Wipe from memory (irreversible)
Redacted.wipeUnsafe(secret)  // now value() throws

// Structural equality (compare without extracting)
Equal.equals(Redacted.make("a"), Redacted.make("a")) // true

// Use with Config
const apiKey = yield* Config.redacted("API_KEY")  // Config<Redacted<string>>
const raw = Redacted.value(apiKey)
```

## Pool

```ts
import { Effect, Pool } from "effect"

// Fixed-size pool
const pool = yield* Pool.make({
  acquire: Effect.sync(() => createConnection()),
  size: 10
})

// Dynamic pool with TTL
const pool = yield* Pool.makeWithTTL({
  acquire: connectToDb(),
  min: 2,
  max: 10,
  timeToLive: "30 seconds",
  timeToLiveStrategy: "usage"  // "creation" or "usage" (default)
})

// Use a resource from the pool (scoped, auto-returned)
yield* Effect.scoped(
  Effect.gen(function*() {
    const conn = yield* Pool.get(pool)
    return yield* conn.query("SELECT 1")
  })
)

// Invalidate a bad item (triggers replacement)
yield* Pool.invalidate(pool, failedItem)

// Concurrency control (permits per item)
const pool = yield* Pool.make({
  acquire: acquireItem,
  size: 10,
  concurrency: 3  // each item handles 3 concurrent uses
})
```

## Cache

```ts
import { Cache, Effect } from "effect"

// Create a cache with TTL
const cache = yield* Cache.make({
  capacity: 1000,
  timeToLive: "5 minutes",
  lookup: (key: string) => fetchFromDb(key)
})

// Get (fetches on miss, returns cached on hit)
// Concurrent requests for same key are deduplicated
const value = yield* Cache.get(cache, "user:123")

// Check without triggering lookup
yield* Cache.has(cache, "key")
yield* Cache.getOption(cache, "key")     // Option, no lookup
yield* Cache.getSuccess(cache, "key")    // only if cached & successful

// Manually set a value
yield* Cache.set(cache, "key", value)

// Invalidate
yield* Cache.invalidate(cache, "user:123")
yield* Cache.invalidateAll(cache)

// Refresh (re-fetch and update cache)
yield* Cache.refresh(cache, "user:123")

// Dynamic TTL based on key/result
const cache = yield* Cache.makeWith({
  capacity: 100,
  lookup: (key) => fetchData(key),
  timeToLive: (exit, key) =>
    Exit.isFailure(exit) ? "1 second" : "1 hour"
})
```

## Resource

Managed values that can be refreshed:

```ts
import { Effect, Resource } from "effect"

// Manual refresh
const resource = yield* Resource.manual(fetchConfig())
const config = yield* Resource.get(resource)
yield* Resource.refresh(resource)  // re-run the acquire effect

// Auto-refresh on a schedule
const resource = yield* Resource.auto(
  fetchConfig(),
  Schedule.spaced("5 minutes")
)
// Spawns a background fiber that refreshes periodically
// Failed refresh preserves the previous value

const config = yield* Resource.get(resource)
```

## Duration

```ts
import { Duration } from "effect"

// String syntax (preferred in APIs)
"5 seconds"
"100 millis"
"2 minutes"
"1 hour"

// Programmatic
Duration.seconds(5)
Duration.millis(100)
Duration.minutes(2)

// Arithmetic
Duration.sum(a, b)
Duration.times(d, 3)

// Comparison
Duration.isGreaterThan(a, b)
Duration.isLessThanOrEqualTo(a, b)

// Convert
Duration.toMillis(d)
Duration.toSeconds(d)
Duration.toMinutes(d)
```
