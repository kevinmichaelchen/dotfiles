# Data Types & Pattern Matching (Effect v4)

## Table of Contents

- [Data.TaggedEnum](#datataggedenum)
- [Data.Class & Data.TaggedClass](#dataclass--datataggedclass)
- [Match Module](#match-module)
- [Optic Module](#optic-module)
- [Option](#option)
- [Result](#result)

## Data.TaggedEnum

Discriminated unions with structural equality:

```ts
import { Data, Equal, Match } from "effect"

type Shape = Data.TaggedEnum<{
  Circle: { radius: number }
  Rectangle: { width: number; height: number }
  Triangle: { base: number; height: number }
}>
const Shape = Data.taggedEnum<Shape>()

// Constructors (plain objects, not class instances)
const circle = Shape.Circle({ radius: 5 })
const rect = Shape.Rectangle({ width: 10, height: 20 })

// Structural equality
Equal.equals(Shape.Circle({ radius: 5 }), Shape.Circle({ radius: 5 })) // true

// Type guard: $is
const isCircle = Shape.$is("Circle")
isCircle(circle) // true — narrows type to Circle variant

// Pattern matching: $match (exhaustive)
const area = Shape.$match({
  Circle: ({ radius }) => Math.PI * radius ** 2,
  Rectangle: ({ width, height }) => width * height,
  Triangle: ({ base, height }) => 0.5 * base * height
})
area(circle) // Math.PI * 25

// Data-first $match
Shape.$match(circle, {
  Circle: ({ radius }) => Math.PI * radius ** 2,
  Rectangle: ({ width, height }) => width * height,
  Triangle: ({ base, height }) => 0.5 * base * height
})
```

### Generic TaggedEnum (up to 4 type params)

```ts
type Result<E, A> = Data.TaggedEnum<{
  Ok: { value: A }
  Err: { error: E }
}>
interface ResultDefinition extends Data.TaggedEnum.WithGenerics<2> {
  readonly taggedEnum: Result<this["A"], this["B"]>
}
const Result = Data.taggedEnum<ResultDefinition>()

const ok = Result.Ok({ value: 42 })    // infers { _tag: "Ok", value: number }
const err = Result.Err({ error: "x" }) // infers { _tag: "Err", error: string }
```

## Data.Class & Data.TaggedClass

```ts
import { Data } from "effect"

// Plain data class with structural equality
class Point extends Data.Class<{ x: number; y: number }> {}

const p1 = new Point({ x: 1, y: 2 })
const p2 = new Point({ x: 1, y: 2 })
Equal.equals(p1, p2) // true

// Tagged data class (has _tag field)
class Circle extends Data.TaggedClass("Circle")<{ radius: number }> {}
const c = new Circle({ radius: 5 })
c._tag // "Circle"

// No-field variants accept void
class Empty extends Data.Class {}
new Empty() // valid
```

### Data.Error & Data.TaggedError

Yieldable errors (can be yielded in `Effect.gen` to fail):

```ts
// Plain error
class MyError extends Data.Error<{ code: number; message: string }> {}

// Tagged error (has _tag, works with catchTag)
class NotFound extends Data.TaggedError("NotFound")<{ resource: string }> {}

const program = Effect.gen(function*() {
  return yield* new NotFound({ resource: "/users/42" })
}).pipe(
  Effect.catchTag("NotFound", (e) => Effect.succeed(`missing: ${e.resource}`))
)
```

**Note**: For new code, prefer `Schema.TaggedErrorClass` over `Data.TaggedError` — it adds schema validation and HTTP status support.

## Match Module

Exhaustive pattern matching:

```ts
import { Match } from "effect"

// Match on tagged unions
const area = Match.type<Shape>().pipe(
  Match.tag("Circle", ({ radius }) => Math.PI * radius ** 2),
  Match.tag("Rectangle", ({ width, height }) => width * height),
  Match.tag("Triangle", ({ base, height }) => 0.5 * base * height),
  Match.exhaustive
)

// Match on values
const describe = Match.value(someShape).pipe(
  Match.tag("Circle", ({ radius }) => `Circle with radius ${radius}`),
  Match.orElse(() => "Other shape")
)

// Match on predicates
const classify = Match.type<number>().pipe(
  Match.when((n) => n < 0, () => "negative"),
  Match.when((n) => n === 0, () => "zero"),
  Match.when((n) => n > 0, () => "positive"),
  Match.exhaustive
)

// Inline tag-exhaustive matching (shortcut)
Match.valueTags(result, {
  Success: (v) => v.data,
  Error: (e) => e.message
})

// whenOr / whenAnd
Match.whenOr({ _tag: "A" }, { _tag: "B" }, () => "matched A or B")
Match.whenAnd({ age: (n: number) => n > 18 }, { role: "admin" }, () => "ok")
```

### Finalizers

| Finalizer | Returns | Behavior |
|-----------|---------|----------|
| `exhaustive` | `T` | Type error if non-exhaustive |
| `orElse(f)` | `T \| R` | Fallback when no match |
| `orElseAbsurd` | `T` | Throws if no match |
| `option` | `Option<T>` | Wraps in Option |

## Optic Module

Functional optics for immutable updates:

```ts
import { Optic } from "effect"

interface Address { street: string; city: string }
interface Person { name: string; address: Address }

// Lens: focus on a field via .key()
const cityLens = Optic.id<Person>().key("address").key("city")

// Get
cityLens.get(person) // "Springfield"

// Set (returns new object, preserves referential identity of untouched parts)
cityLens.replace("Shelbyville", person)

// Modify
cityLens.modify((city) => city.toUpperCase())(person)

// Prism: optional focus (read can fail)
const circleLens = Optic.id<Shape>().tag("Circle").key("radius")
circleLens.getResult(shape) // Result<number, string>

// Traversal: focus on multiple elements
const allLikes = Optic.id<State>()
  .key("posts")
  .forEach((post) => post.key("likes"))
Optic.getAll(allLikes)(state) // Array<number>
allLikes.modifyAll((n) => n + 1)(state)

// Validation checks
Optic.id<number>().check(Schema.isGreaterThan(0), Schema.isInt())
```

## Option

```ts
import { Option } from "effect"

// Construction
Option.some(42)            // Some(42)
Option.none()              // None
Option.fromNullishOr(value) // Some(value) or None (filters null and undefined)

// Pattern matching
Option.match(opt, {
  onNone: () => "empty",
  onSome: (value) => `got ${value}`
})

// Chaining
option.pipe(
  Option.map((x) => x + 1),
  Option.flatMap((x) => x > 0 ? Option.some(x) : Option.none()),
  Option.getOrElse(() => 0)
)

// To/from Effect
Effect.fromNullishOr(nullableValue) // Effect that fails if null/undefined
```

## Result

```ts
import { Result } from "effect"

// Construction
Result.succeed(42)        // Ok(42)
Result.fail("error")      // Err("error")

// Pattern matching
Result.match(result, {
  onFailure: (err) => `Error: ${err}`,
  onSuccess: (val) => `Value: ${val}`
})

// Chaining
result.pipe(
  Result.map((x) => x + 1),
  Result.flatMap((x) => x > 0 ? Result.succeed(x) : Result.fail("negative"))
)
```
