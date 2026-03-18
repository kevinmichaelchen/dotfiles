# Observability: Logging, Metrics & Tracing (Effect v4)

## Table of Contents

- [Logging](#logging)
- [Log Levels](#log-levels)
- [Log Annotations & Spans](#log-annotations--spans)
- [Logger Configuration](#logger-configuration)
- [OTLP Tracing](#otlp-tracing)
- [Spans](#spans)
- [Metrics](#metrics)
- [Tracking Effects with Metrics](#tracking-effects-with-metrics)

## Logging

```ts
import { Effect } from "effect"

Effect.gen(function*() {
  yield* Effect.logDebug("Debug message")
  yield* Effect.logInfo("Info message")
  yield* Effect.log("Default level message")
  yield* Effect.logWarning("Warning message")
  yield* Effect.logError("Error occurred")
  yield* Effect.logFatal("Fatal error")

  // Structured logging with cause
  yield* Effect.logError("Operation failed", cause)
})
```

## Log Levels

```ts
import { Logger, References } from "effect"

// Set minimum log level via Reference
const program = myEffect.pipe(
  Effect.provideService(References.MinimumLogLevel, "Warning")
)
```

## Log Annotations & Spans

```ts
// Add key-value pairs to all log messages in scope
const program = myEffect.pipe(
  Effect.annotateLogs({ requestId: "abc-123", userId: "user-42" })
)

// Scoped annotations (automatic cleanup)
yield* Effect.annotateLogsScoped("requestId", "req-123")

// Log spans (timing context)
const program = myEffect.pipe(
  Effect.withLogSpan("myOperation")
)
// Logs will include: myOperation=45ms

// With Effect.fn (use combinator args, not .pipe)
export const process = Effect.fn("process")(
  function*(input: string) {
    yield* Effect.logInfo("processing")
    return input.length
  },
  Effect.annotateLogs({ fn: "process" })
)
```

## Logger Configuration

```ts
import { Layer, Logger } from "effect"

// Built-in console loggers
Logger.consoleLogFmt        // key=value format
Logger.consoleStructured    // JS object format
Logger.consoleJson          // single-line JSON
Logger.consolePretty()      // colorized pretty-print (options: colors, stderr, mode)

// Replace default logger
const program = myEffect.pipe(
  Effect.provide(Logger.consoleJson)
)

// Create a logger layer (replaces default)
const LoggerLayer = Logger.layer([Logger.consoleJson])

// Multiple loggers (all emit for each log)
const MultiLoggerLayer = Logger.layer([Logger.consoleJson, Logger.consolePretty()])

// Merge with existing loggers
const AdditionalLoggers = Logger.layer([Logger.consoleJson], { mergeWithExisting: true })

// Batched logger (aggregates over time window)
const batchedLogger = Logger.batched(Logger.formatJson, {
  window: "5 seconds",
  flush: (messages) => Effect.sync(() => sendToService(messages))
})

// File logger
const FileLogger = Logger.toFile("/var/log/app.log", {
  flag: "a+",
  batchWindow: "5 seconds"
})
```

## OTLP Tracing

```ts
import { OtlpLogger, OtlpTracer } from "effect/unstable/observability"

// OTLP tracer layer (sends spans to collector)
const TracerLayer = OtlpTracer.layer({
  serviceName: "my-service",
  url: "http://collector:4318/v1/traces"
})

// OTLP logger layer (sends logs to collector)
const LoggerLayer = OtlpLogger.layer({
  serviceName: "my-service",
  url: "http://collector:4318/v1/logs"
})

// Combine both
const ObservabilityLayer = Layer.mergeAll(TracerLayer, LoggerLayer)
```

## Spans

```ts
// Add spans for tracing
const program = myEffect.pipe(
  Effect.withSpan("operationName")
)

// Span annotations
const program = myEffect.pipe(
  Effect.withSpan("operationName"),
  Effect.annotateSpans({ key: "value" })
)

// Annotate current span
yield* Effect.annotateCurrentSpan("user.id", "123")

// Effect.fn automatically creates spans from the name
export const fetchUser = Effect.fn("fetchUser")(function*(id: number) {
  // Automatically wrapped in a "fetchUser" span
  return yield* db.query(`SELECT * FROM users WHERE id = ${id}`)
})

// Span kinds
Effect.withSpan("handle-request", { kind: "server" })
// Kinds: "internal" | "server" | "client" | "producer" | "consumer"

// External spans (from other tracing systems)
const externalSpan = Tracer.externalSpan({
  spanId: "span-abc-123",
  traceId: "trace-xyz-789",
  sampled: true
})
yield* effect.pipe(Effect.withSpan("child", { parent: externalSpan }))

// Access current span
const span = yield* Effect.currentSpan
// span.spanId, span.traceId, span.attributes, span.sampled

// Link spans
yield* effect.pipe(
  Effect.withSpan("main"),
  Effect.linkSpans(spanA),
  Effect.linkSpans(spanB)
)
```

## Metrics

```ts
import { Metric } from "effect"

// Counter
const requestCount = Metric.counter("http.requests.total")
yield* Metric.update(requestCount, 1)
yield* Metric.update(requestCount, 5)

// Gauge
const activeConnections = Metric.gauge("db.connections.active")
yield* Metric.update(activeConnections, 42)

// Frequency (count discrete string values)
const statusCodes = Metric.frequency("http.status_codes")
yield* Metric.update(statusCodes, "200")

// Histogram
const requestDuration = Metric.histogram("http.request.duration", {
  boundaries: [10, 50, 100, 250, 500, 1000]
  // or: Metric.linearBoundaries({ start: 0, width: 50, count: 20 })
})
yield* Metric.update(requestDuration, 150)

// Summary (quantiles over sliding time window)
const responseSizes = Metric.summary("http.response.size", {
  maxAge: "1 minute",
  maxSize: 100,
  quantiles: [0.5, 0.9, 0.99]
})

// Attributes (tags for grouping/filtering)
const taggedCounter = Metric.withAttributes(requestCount, {
  method: "GET",
  endpoint: "/users"
})
yield* Metric.update(taggedCounter, 1)

// Read current metric state
const state = yield* Metric.value(requestCount)
const allMetrics = yield* Metric.snapshot
```

## Tracking Effects with Metrics

```ts
// Track all outcomes (success, failure, defect)
yield* myEffect.pipe(Effect.track(counter))

// Track only successes
yield* myEffect.pipe(Effect.trackSuccesses(counter))

// Track only errors
yield* myEffect.pipe(Effect.trackErrors(counter))

// Track only defects
yield* myEffect.pipe(Effect.trackDefects(counter))

// Track duration (timer histogram)
const timer = Metric.timer("operation_duration_ms")
yield* myEffect.pipe(Effect.trackDuration(timer))

// Timer with custom converter
yield* myEffect.pipe(
  Effect.trackDuration(durationGauge, (duration) =>
    Duration.toMinutes(duration)
  )
)
```
