# Testing Patterns (Effect v4)

## Table of Contents

- [Imports](#imports)
- [Basic Effect Tests](#basic-effect-tests)
- [Parameterized Tests](#parameterized-tests)
- [TestClock](#testclock)
- [Live Tests](#live-tests)
- [Property-Based Tests](#property-based-tests)
- [Shared Layers](#shared-layers)
- [Test Service Implementations](#test-service-implementations)
- [Assertions](#assertions)

## Imports

```ts
import { assert, describe, it, layer } from "@effect/vitest"
import { Effect, Fiber, Schema } from "effect"
import { TestClock } from "effect/testing"
```

**Never** import `expect` or `it` from `vitest` directly.

## Basic Effect Tests

```ts
describe("MyFeature", () => {
  it.effect("does the thing", () =>
    Effect.gen(function*() {
      const result = yield* myEffect
      assert.strictEqual(result, expected)
    }))
})
```

## Parameterized Tests

```ts
it.effect.each([
  { input: " Ada ", expected: "ada" },
  { input: " Lin ", expected: "lin" }
])("normalizes %#", ({ input, expected }) =>
  Effect.gen(function*() {
    assert.strictEqual(input.trim().toLowerCase(), expected)
  }))
```

## TestClock

Use `TestClock` to control time in tests without waiting:

```ts
it.effect("handles timeout", () =>
  Effect.gen(function*() {
    const fiber = yield* Effect.forkChild(
      Effect.sleep(60_000).pipe(Effect.as("done"))
    )
    yield* TestClock.adjust(60_000)
    const value = yield* Fiber.join(fiber)
    assert.strictEqual(value, "done")
  }))
```

## Live Tests

Use `it.live` when you need real runtime services (real clock, real random):

```ts
it.live("uses real time", () =>
  Effect.gen(function*() {
    const start = Date.now()
    yield* Effect.sleep(1)
    assert.isTrue(Date.now() >= start)
  }))
```

## Property-Based Tests

Use Schema-based arbitraries:

```ts
it.effect.prop("reversing twice is identity", [Schema.String], ([value]) =>
  Effect.gen(function*() {
    const reversed = value.split("").reverse().reverse().join("")
    assert.strictEqual(reversed, value)
  }))
```

## Shared Layers

Use `layer(...)` to create a shared layer for a test block. The layer is built once and torn down in `afterAll`:

```ts
layer(TodoRepo.layerTest)("TodoRepo", (it) => {
  it.effect("creates items", () =>
    Effect.gen(function*() {
      const repo = yield* TodoRepo
      yield* repo.create("Write docs")
      const items = yield* repo.list
      assert.strictEqual(items.length, 1)
    }))

  it.effect("layer is shared across tests", () =>
    Effect.gen(function*() {
      const repo = yield* TodoRepo
      const items = yield* repo.list
      // Item from previous test is still present
      assert.strictEqual(items.length, 1)
    }))
})
```

## Test Service Implementations

Create test doubles using `Ref` for state:

```ts
class TodoRepoTestRef
  extends ServiceMap.Service<TodoRepoTestRef, Ref.Ref<Array<Todo>>>()("app/TodoRepoTestRef")
{
  static readonly layer = Layer.effect(TodoRepoTestRef, Ref.make(Array.empty()))
}

class TodoRepo extends ServiceMap.Service<TodoRepo, {
  create(title: string): Effect.Effect<Todo>
  readonly list: Effect.Effect<ReadonlyArray<Todo>>
}>()("app/TodoRepo") {
  static readonly layerTest = Layer.effect(
    TodoRepo,
    Effect.gen(function*() {
      const store = yield* TodoRepoTestRef

      const create = Effect.fn("TodoRepo.create")(function*(title: string) {
        const todos = yield* Ref.get(store)
        const todo = { id: todos.length + 1, title }
        yield* Ref.set(store, [...todos, todo])
        return todo
      })

      const list = Ref.get(store)

      return TodoRepo.of({ create, list })
    })
  ).pipe(
    Layer.provideMerge(TodoRepoTestRef.layer)
  )
}
```

For one-off test layers without needing per-test state manipulation:

```ts
it.effect("with inline layer", () =>
  Effect.gen(function*() {
    const service = yield* MyService
    const result = yield* service.doThing()
    assert.strictEqual(result, "expected")
  }).pipe(Effect.provide(MyService.layerTest)))
```

## Assertions

Use `assert` from `@effect/vitest`, **never** `expect`:

```ts
assert.strictEqual(a, b)        // ===
assert.deepStrictEqual(a, b)    // deep equality
assert.isTrue(value)
assert.isFalse(value)
assert.isUndefined(value)
assert.isDefined(value)
assert.deepEqual(a, b)          // deep loose equality
assert.notDeepEqual(a, b)
```
