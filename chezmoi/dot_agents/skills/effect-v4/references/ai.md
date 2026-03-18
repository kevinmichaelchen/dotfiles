# AI Module (Effect v4)

## Table of Contents

- [Imports](#imports)
- [Language Model](#language-model)
- [Structured Output](#structured-output)
- [Tools](#tools)
- [Toolkits](#toolkits)
- [Chat Sessions](#chat-sessions)
- [Agentic Loops](#agentic-loops)
- [Prompts](#prompts)
- [Error Handling](#error-handling)
- [Providers](#providers)

## Imports

```ts
import { Chat, LanguageModel, Prompt, Tool, Toolkit } from "effect/unstable/ai"
import { AnthropicProvider } from "@anthropic-ai/effect"
import { OpenAiProvider } from "@openai/effect"
```

## Language Model

```ts
// Generate text
const response = yield* LanguageModel.generateText({
  prompt: "Explain Effect in one sentence"
})
console.log(response.text)
console.log(response.usage.outputTokens.total)
console.log(response.finishReason)

// With system message
const response = yield* LanguageModel.generateText({
  system: "You are a helpful assistant.",
  prompt: "What is Effect?"
})

// Streaming
const stream = LanguageModel.streamText({
  prompt: "Write a story"
})
// Stream<Response.AnyPart, AiError, LanguageModel>
```

## Structured Output

```ts
// Generate typed objects using Schema
const result = yield* LanguageModel.generateObject({
  prompt: "Analyze the sentiment: 'I love Effect!'",
  objectName: "sentiment",
  schema: Schema.Struct({
    sentiment: Schema.Literal("positive", "negative", "neutral"),
    confidence: Schema.Number,
    reasoning: Schema.String
  })
})
result.value.sentiment // "positive"
```

## Tools

```ts
// Define a tool
const WeatherTool = Tool.make("getWeather", {
  description: "Get current weather for a city",
  parameters: Schema.Struct({
    city: Schema.String.annotate({ description: "City name" })
  }),
  success: Schema.Struct({
    temperature: Schema.Number,
    condition: Schema.String
  }),
  failureMode: "error"  // or "return" — how handler errors propagate
}, Effect.fn(function*({ city }) {
  const data = yield* fetchWeather(city)
  return { temperature: data.temp, condition: data.condition }
}))

// Provider-defined tool (e.g., web search)
const webSearch = Tool.providerDefined(config)

// Use tool with generateText
const response = yield* LanguageModel.generateText({
  prompt: "What's the weather in Paris?",
  tools: [WeatherTool],
  toolChoice: "auto"  // "auto" | "required" | "none"
})

// Access tool calls and results
for (const call of response.toolCalls) {
  console.log(call.name, call.id, call.params)
}
for (const result of response.toolResults) {
  console.log(result.name, result.result, result.isFailure)
}
```

## Toolkits

Group related tools:

```ts
const ProductToolkit = Toolkit.make(
  Tool.make("search", {
    description: "Search products",
    parameters: Schema.Struct({ query: Schema.String }),
    success: Schema.Array(Product)
  }, searchHandler),
  Tool.make("getInventory", {
    description: "Check inventory",
    parameters: Schema.Struct({ productId: Schema.String }),
    success: Schema.Struct({ available: Schema.Number })
  }, inventoryHandler)
)

// Convert toolkit to a Layer with handlers
const ToolkitLayer = ProductToolkit.toLayer(Effect.gen(function*() {
  return {
    search: Effect.fn("search")(function*({ query }) {
      return yield* searchProducts(query)
    }),
    getInventory: Effect.fn("getInventory")(function*({ productId }) {
      return { available: 42 }
    })
  }
}))
```

## Chat Sessions

```ts
// Create a chat from a prompt
const session = yield* Chat.fromPrompt(
  Prompt.empty.pipe(
    Prompt.setSystem("You are a helpful coding assistant.")
  )
)

// Generate a response (history auto-managed)
const response = yield* session.generateText({
  prompt: "Help me write a function"
})
console.log(response.text)

// Access conversation history
const history = yield* Ref.get(session.history)

// Export/restore for persistence
const json = yield* session.exportJson
const restored = yield* Chat.fromJson(json)
```

## Agentic Loops

Chat sessions with tools for multi-turn agent loops:

```ts
const session = yield* Chat.fromPrompt([
  { role: "system", content: "You are an assistant that can use tools." },
  { role: "user", content: question }
])

// Loop until the model stops calling tools
while (true) {
  const response = yield* session.generateText({
    prompt: [],
    toolkit: tools
  }).pipe(Effect.provide(modelLayer))

  if (response.toolCalls.length > 0) {
    continue  // Chat auto-adds tool results to history
  }
  return response.text
}
```

## Prompts

```ts
import { Prompt } from "effect/unstable/ai"

// Empty prompt
Prompt.empty

// From text (creates a user message)
Prompt.make("What is Effect?")

// From messages
Prompt.make([
  { role: "system", content: "You are helpful." },
  { role: "user", content: "Hello" }
])

// Set system message
const prompt = Prompt.empty.pipe(Prompt.setSystem("You are a TypeScript expert."))

// Combine prompts
Prompt.concat(prompt1, prompt2)
```

## Error Handling

```ts
import { AiError } from "effect/unstable/ai"

// AiError has a .reason discriminated union
effect.pipe(
  Effect.catchTag("AiError", (error) => {
    const reason = error.reason
    reason._tag         // discriminant
    reason.isRetryable  // boolean
    reason.retryAfter   // optional Duration

    // Reason types:
    // RateLimitError, QuotaExhaustedError, AuthenticationError,
    // ContentPolicyError, InvalidRequestError, InvalidUserInputError,
    // InternalProviderError, NetworkError, InvalidOutputError,
    // StructuredOutputError, UnsupportedSchemaError,
    // ToolNotFoundError, ToolParameterValidationError, InvalidToolResultError
  })
)
```

## Providers

```ts
// Anthropic
import { AnthropicProvider } from "@anthropic-ai/effect"

const AnthropicLayer = AnthropicProvider.layer({
  model: "claude-sonnet-4-20250514",
  apiKey: Config.secret("ANTHROPIC_API_KEY")
})

// OpenAI
import { OpenAiProvider } from "@openai/effect"

const OpenAiLayer = OpenAiProvider.layer({
  model: "gpt-4o",
  apiKey: Config.secret("OPENAI_API_KEY")
})

// Provide to your program
program.pipe(Effect.provide(AnthropicLayer))
```
