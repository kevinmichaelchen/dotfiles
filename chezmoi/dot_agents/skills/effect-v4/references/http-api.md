# HttpApi Patterns (Effect v4)

## Table of Contents

- [Imports](#imports)
- [Domain Models](#domain-models)
- [Error Definitions](#error-definitions)
- [API Group Definition](#api-group-definition)
- [Root API](#root-api)
- [Middleware](#middleware)
- [Handler Implementation](#handler-implementation)
- [Server Wiring](#server-wiring)
- [Typed Client](#typed-client)
- [Web Handler (Serverless)](#web-handler-serverless)

## Imports

```ts
// API definition (shared between client and server)
import { HttpApi, HttpApiEndpoint, HttpApiError, HttpApiGroup, HttpApiMiddleware, HttpApiSchema, HttpApiSecurity, OpenApi } from "effect/unstable/httpapi"

// HTTP transport
import { FetchHttpClient, HttpClient, HttpClientRequest, HttpClientResponse, HttpRouter, HttpServer, HttpServerResponse } from "effect/unstable/http"

// Server runtime
import { NodeHttpServer, NodeRuntime } from "@effect/platform-node"
```

## Domain Models

```ts
import { Schema } from "effect"

export const UserId = Schema.Int.pipe(Schema.brand("UserId"))
export type UserId = typeof UserId.Type

export class User extends Schema.Class<User>("User")({
  id: UserId,
  name: Schema.String,
  email: Schema.String
}) {}
```

## Error Definitions

```ts
export class UserNotFound extends Schema.TaggedErrorClass<UserNotFound>()(
  "UserNotFound", {}, { httpApiStatus: 404 }
) {}

export class SearchQueryTooShort
  extends Schema.TaggedErrorClass<SearchQueryTooShort>()("SearchQueryTooShort", {}, { httpApiStatus: 422 })
{
  static readonly minimumLength = 2
}

// Wrapper error for service methods
export class UsersError extends Schema.TaggedErrorClass<UsersError>()("UsersError", {
  reason: Schema.Union([UserNotFound, SearchQueryTooShort])
}) {}
```

## API Group Definition

API definitions must be **separate** from server implementation (for sharing with clients).

```ts
export class UsersApiGroup extends HttpApiGroup.make("users")
  .add(
    HttpApiEndpoint.get("list", "/", {
      query: { search: Schema.optional(Schema.String) },
      success: Schema.Array(User)
    }),
    HttpApiEndpoint.get("getById", "/:id", {
      params: {
        id: Schema.FiniteFromString.pipe(Schema.decodeTo(UserId))
      },
      success: User,
      error: UserNotFound.pipe(HttpApiSchema.asNoContent({
        decode: () => new UserNotFound()
      }))
    }),
    HttpApiEndpoint.post("create", "/", {
      payload: Schema.Struct({ name: Schema.String, email: Schema.String }),
      success: User
    })
  )
  .middleware(Authorization)
  .prefix("/users")
  .annotateMerge(OpenApi.annotations({
    title: "Users",
    description: "User management"
  }))
{}
```

### Endpoint options

- `query`: query parameters (GET requests)
- `payload`: body (POST/PUT/PATCH) or query (GET)
- `params`: path parameters (decode from strings)
- `success`: response schema (or array of schemas for multiple content types)
- `error`: error schema(s)
- `headers`: header schemas

### Multiple response types

```ts
HttpApiEndpoint.get("search", "/search", {
  payload: { search: Schema.String },
  success: [
    Schema.Array(User),
    Schema.String.pipe(HttpApiSchema.asText({ contentType: "text/csv" }))
  ],
  error: [
    SearchQueryTooShort.pipe(HttpApiSchema.asNoContent({ decode: () => new SearchQueryTooShort() })),
    HttpApiError.RequestTimeoutNoContent
  ]
})
```

## Root API

```ts
export class Api extends HttpApi.make("my-api")
  .add(UsersApiGroup)
  .add(SystemApiGroup)
  .annotateMerge(OpenApi.annotations({ title: "My API" }))
{}
```

## Middleware

### Definition (shared)

```ts
export class CurrentUser extends ServiceMap.Service<CurrentUser, User>()("myapp/CurrentUser") {}

export class Unauthorized extends Schema.TaggedErrorClass<Unauthorized>()(
  "Unauthorized", { message: Schema.String }, { httpApiStatus: 401 }
) {}

export class Authorization extends HttpApiMiddleware.Service<Authorization, {
  provides: CurrentUser
  requires: never
}>()("myapp/Authorization", {
  requiredForClient: true,
  security: { bearer: HttpApiSecurity.bearer },
  error: Unauthorized
}) {}
```

### Server implementation

```ts
const AuthorizationLayer = Layer.effect(
  Authorization,
  Effect.gen(function*() {
    return Authorization.of({
      bearer: Effect.fn(function*(httpEffect, { credential }) {
        const token = Redacted.value(credential)
        const user = yield* validateToken(token)
        return yield* Effect.provideService(httpEffect, CurrentUser, user)
      })
    })
  })
)
```

### Client implementation

```ts
const AuthorizationClient = HttpApiMiddleware.layerClient(
  Authorization,
  Effect.fn(function*({ next, request }) {
    return yield* next(HttpClientRequest.bearerToken(request, "my-token"))
  })
)
```

## Handler Implementation

```ts
export const UsersApiHandlers = HttpApiBuilder.group(
  Api,
  "users",
  Effect.fn(function*(handlers) {
    const users = yield* Users

    return handlers
      .handle("list", ({ query }) =>
        users.list(query.search).pipe(Effect.orDie))
      .handle("getById", ({ params }) =>
        users.getById(params.id).pipe(
          Effect.catchReasons("UsersError", {
            UserNotFound: (e) => Effect.fail(e)
          }, Effect.die)
        ))
      .handle("create", ({ payload }) =>
        users.create(payload).pipe(Effect.orDie))
      .handle("me", () => CurrentUser.asEffect())
  })
).pipe(
  Layer.provide([Users.layer, AuthorizationLayer])
)
```

## Server Wiring

```ts
const ApiRoutes = HttpApiBuilder.layer(Api, {
  openapiPath: "/openapi.json"
}).pipe(
  Layer.provide([UsersApiHandlers, SystemApiHandlers])
)

const DocsRoute = HttpApiScalar.layer(Api, { path: "/docs" })

const AllRoutes = Layer.mergeAll(ApiRoutes, DocsRoute)

const HttpServerLayer = HttpRouter.serve(AllRoutes).pipe(
  Layer.provide(NodeHttpServer.layer(createServer, { port: 3000 }))
)

Layer.launch(HttpServerLayer).pipe(NodeRuntime.runMain)
```

## Typed Client

```ts
export class ApiClient extends ServiceMap.Service<ApiClient, HttpApiClient.ForApi<typeof Api>>()("myapp/ApiClient") {
  static readonly layer = Layer.effect(
    ApiClient,
    HttpApiClient.make(Api, {
      transformClient: (client) =>
        client.pipe(
          HttpClient.mapRequest(flow(
            HttpClientRequest.prependUrl("http://localhost:3000")
          )),
          HttpClient.retryTransient({ schedule: Schedule.exponential(100), times: 3 })
        )
    })
  ).pipe(
    Layer.provide(AuthorizationClient),
    Layer.provide(FetchHttpClient.layer)
  )
}
```

## Web Handler (Serverless)

```ts
export const { handler, dispose } = HttpRouter.toWebHandler(AllRoutes.pipe(
  Layer.provide(HttpServer.layerServices)
))
```

## Simple Routes (without HttpApi)

```ts
const HealthRoutes = HttpRouter.use(Effect.fn(function*(router) {
  yield* router.add("GET", "/health", Effect.succeed(HttpServerResponse.text("ok")))
}))
```
