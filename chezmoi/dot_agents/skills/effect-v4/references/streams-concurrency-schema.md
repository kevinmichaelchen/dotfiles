# Streams, Concurrency, Schema & Scheduling (Effect v4)

## Table of Contents

- [Schema](#schema)
- [Stream Creation](#stream-creation)
- [Stream Consumption](#stream-consumption)
- [Concurrency Patterns](#concurrency-patterns)
- [Schedule](#schedule)
- [Request Batching](#request-batching)
- [STM / Transactional Collections](#stm--transactional-collections)

## Schema

### Data classes

```ts
import { Schema } from "effect"

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

### Error classes

```ts
// Tagged error (has _tag field, works with catchTag)
export class NotFoundError extends Schema.TaggedErrorClass<NotFoundError>()(
  "NotFoundError",
  { id: Schema.String },
  { httpApiStatus: 404 }  // optional
) {}

// Non-tagged error
export class SmtpError extends Schema.ErrorClass<SmtpError>("SmtpError")({
  cause: Schema.Defect
}) {}
```

### Decoding

```ts
Schema.decodeUnknownSync(MySchema)(input)    // throws on failure
Schema.decodeUnknownEffect(MySchema)(input)  // returns Effect
```

### Path parameter bridging

```ts
Schema.FiniteFromString.pipe(Schema.decodeTo(UserId))
```

## Stream Creation

```ts
import { Effect, Queue, Schedule, Stream } from "effect"

// From iterable
Stream.fromIterable([1, 2, 3])

// Polling with schedule
Stream.fromEffectSchedule(Effect.succeed(42), Schedule.spaced("30 seconds"))

// Paginated APIs
Stream.paginate(0, Effect.fn(function*(page) {
  const results = yield* fetchPage(page)
  const next = results.length > 0 ? Option.some(page + 1) : Option.none()
  return [results, next] as const
}))

// From async iterable
Stream.fromAsyncIterable(asyncIter(), (cause) => new MyError({ cause }))

// From event listener
Stream.fromEventListener<PointerEvent>(element, "click")

// Callback-based
Stream.callback<T>(Effect.fn(function*(queue) {
  function onEvent(value: T) { Queue.offerUnsafe(queue, value) }
  yield* Effect.acquireRelease(
    Effect.sync(() => source.on("data", onEvent)),
    () => Effect.sync(() => source.off("data", onEvent))
  )
}))

// Node.js readable
NodeStream.fromReadable({
  evaluate: () => Readable.from(["Hello"]),
  onError: (cause) => new StreamError({ cause })
})
```

## Stream Consumption

```ts
// Pure transforms
stream.pipe(Stream.map((x) => x + 1))
stream.pipe(Stream.filter((x) => x > 0))

// Effectful transforms with concurrency
stream.pipe(Stream.mapEffect(enrichFn, { concurrency: 4 }))

// FlatMap (one-to-many)
stream.pipe(Stream.flatMap((x) => Stream.fromIterable(expand(x)), { concurrency: 2 }))

// Terminal operations
Stream.runCollect(stream)                        // -> Effect<Array<T>>
Stream.runDrain(stream)                          // -> Effect<void>
Stream.runForEach(stream, (x) => Effect.log(x))  // -> Effect<void>
Stream.runFold(stream, () => 0, (acc, x) => acc + x)
Stream.runHead(stream)                           // -> Effect<Option<T>>
Stream.runLast(stream)                           // -> Effect<Option<T>>
Stream.run(stream, Sink.sum)                     // with Sink

// Windowing
stream.pipe(Stream.take(10))
stream.pipe(Stream.drop(5))
stream.pipe(Stream.takeWhile((x) => x < 100))
```

## Concurrency Patterns

### Parallel execution

```ts
// Run effects in parallel, collect results
Effect.all([effectA, effectB, effectC], { concurrency: "unbounded" })

// ForEach with concurrency
Effect.forEach(items, processFn, { concurrency: 4 })
```

### Fibers

```ts
// Fork a child fiber (interrupted when parent scope closes)
const fiber = yield* Effect.forkChild(longRunningEffect)
const result = yield* Fiber.join(fiber)

// Fork scoped (interrupted when enclosing scope closes)
yield* Effect.forkScoped(backgroundTask)

// Fork detached (runs independently)
yield* Effect.forkDetach(fireAndForget)
```

### Refs and mutable state

```ts
const counter = yield* Ref.make(0)
const value = yield* Ref.get(counter)
yield* Ref.set(counter, 42)
yield* Ref.update(counter, (n) => n + 1)
const prev = yield* Ref.getAndUpdate(counter, (n) => n + 1)
```

### Queue

```ts
const queue = yield* Queue.bounded<string>(100)
yield* Queue.offer(queue, "item")
const item = yield* Queue.take(queue)
```

### PubSub

```ts
import { Effect, PubSub, Queue, Stream } from "effect"

const hub = yield* PubSub.bounded<string>(100)
yield* PubSub.publish(hub, "hello")

// Subscribe returns a Queue that receives published messages
const sub = yield* PubSub.subscribe(hub)
const msg = yield* Queue.take(sub)
```

## Schedule

### Constructors

```ts
Schedule.recurs(5)                    // max 5 retries
Schedule.spaced("30 seconds")        // fixed delay
Schedule.exponential("200 millis")   // exponential backoff
```

### Composition

```ts
// Both must continue (cap + backoff)
Schedule.both(Schedule.exponential("250 millis"), Schedule.recurs(6))

// Either continues (fallback)
Schedule.either(Schedule.spaced("2 seconds"), Schedule.recurs(3))
```

### Filtering and capping

```ts
schedule.pipe(
  Schedule.setInputType<MyError>(),
  Schedule.while(({ input }) => input.retryable),
  Schedule.either(Schedule.spaced("10 seconds")),  // cap delay
  Schedule.jittered
)
```

### Usage with Effect

```ts
// Retry on failure
effect.pipe(Effect.retry(mySchedule))

// Retry with schedule builder (infers input type)
effect.pipe(Effect.retry(($) =>
  $(Schedule.spaced("1 second")).pipe(
    Schedule.while(({ input }) => input.retryable)
  )
))

// Repeat on success
effect.pipe(Effect.repeat(Schedule.spaced("1 minute")))
```

## Request Batching

```ts
import { Effect, Exit, Request, RequestResolver } from "effect"

// Define request type
class GetUserById extends Request.Class<
  { readonly id: number },
  User,          // success
  UserNotFound,  // error
  never          // requirements
> {}

// Create resolver
const resolver = yield* RequestResolver.make<GetUserById>(
  Effect.fn(function*(entries) {
    for (const entry of entries) {
      const user = db.get(entry.request.id)
      entry.completeUnsafe(user ? Exit.succeed(user) : Exit.fail(new UserNotFound({ id: entry.request.id })))
    }
  })
).pipe(
  RequestResolver.setDelay("10 millis"),
  RequestResolver.withSpan("resolver"),
  RequestResolver.withCache({ capacity: 1024 })
)

// Use the resolver
const getUserById = (id: number) =>
  Effect.request(new GetUserById({ id }), resolver)

// Concurrent lookups are automatically batched
yield* Effect.forEach([1, 2, 3], getUserById, { concurrency: "unbounded" })
```

## STM / Transactional Collections

```ts
import { Effect, Option, TxHashMap, TxQueue } from "effect"

const map = yield* TxHashMap.make<string, number>()

yield* Effect.transaction(
  Effect.gen(function*() {
    yield* TxHashMap.set(map, "a", 1)
    yield* TxHashMap.set(map, "b", 2)
    const a = (yield* TxHashMap.get(map, "a")).pipe(Option.getOrElse(() => 0))
    if (a > 10) {
      return yield* Effect.interrupt  // rolls back entire transaction
    }
    return a
  })
)
```

Available: `TxHashMap`, `TxHashSet`, `TxQueue`, `TxChunk`, `TxRef`, `TxDeferred`, `TxPubSub`, `TxSemaphore`, `TxSubscriptionRef`, `TxPriorityQueue`, `TxReentrantLock`.
