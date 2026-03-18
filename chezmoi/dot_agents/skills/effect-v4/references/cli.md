# CLI Module (Effect v4)

## Table of Contents

- [Imports](#imports)
- [Basic Command](#basic-command)
- [Flags](#flags)
- [Arguments](#arguments)
- [Subcommands](#subcommands)
- [Running](#running)

## Imports

```ts
import { Argument, Command, Flag } from "effect/unstable/cli"
import { NodeRuntime } from "@effect/platform-node"
```

## Basic Command

```ts
const greet = Command.make("greet", {
  name: Argument.string({ name: "name" })
}, Effect.fn(function*({ name }) {
  yield* Effect.log(`Hello, ${name}!`)
}))

// Run it
Command.run(greet, {
  name: "my-cli",
  version: "1.0.0"
}).pipe(NodeRuntime.runMain)
```

## Flags

```ts
// String flag
Flag.string({ name: "output", aliases: ["o"] })

// Boolean flag
Flag.boolean({ name: "verbose", aliases: ["v"] })

// Choice flag (enum)
Flag.choice({ name: "format", alternatives: ["json", "csv", "table"] })

// Optional with default
Flag.string({ name: "host" }).pipe(Flag.withDefault("localhost"))

// Optional (returns Option)
Flag.optional(Flag.string({ name: "config" }))

// In a command
const build = Command.make("build", {
  output: Flag.string({ name: "output", aliases: ["o"] }),
  verbose: Flag.boolean({ name: "verbose", aliases: ["v"] }),
  format: Flag.choice({ name: "format", alternatives: ["json", "csv"] })
}, Effect.fn(function*({ output, verbose, format }) {
  if (verbose) yield* Effect.log("Verbose mode enabled")
  yield* Effect.log(`Building to ${output} as ${format}`)
}))
```

## Arguments

```ts
// Required string argument
Argument.string({ name: "file" })

// Multiple arguments
const cmd = Command.make("copy", {
  source: Argument.string({ name: "source" }),
  dest: Argument.string({ name: "destination" })
}, Effect.fn(function*({ source, dest }) {
  yield* Effect.log(`Copying ${source} to ${dest}`)
}))
```

## Subcommands

```ts
const add = Command.make("add", {
  file: Argument.string({ name: "file" })
}, Effect.fn(function*({ file }) {
  yield* Effect.log(`Adding ${file}`)
}))

const remove = Command.make("remove", {
  file: Argument.string({ name: "file" })
}, Effect.fn(function*({ file }) {
  yield* Effect.log(`Removing ${file}`)
}))

const cli = Command.make("my-tool").pipe(
  Command.withSubcommands({ add, remove })
)

Command.run(cli, {
  name: "my-tool",
  version: "1.0.0"
}).pipe(NodeRuntime.runMain)
```

## Running

```ts
// Node.js
import { NodeRuntime } from "@effect/platform-node"
Command.run(cli, { name: "app", version: "1.0.0" }).pipe(NodeRuntime.runMain)

// Bun
import { BunRuntime } from "@effect/platform-bun"
Command.run(cli, { name: "app", version: "1.0.0" }).pipe(BunRuntime.runMain)
```
