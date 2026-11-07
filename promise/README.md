# Promise

A small, strictly typed Promise implementation for Roblox, written in Luau.

## Installation

Copy `Promise.luau` into your project, for example under `ReplicatedStorage`, and require it:

```lua
local Promise = require(ReplicatedStorage.Promise)
```

## Usage

```lua
local function delay(seconds: number): Promise.Promise<number>
	return Promise.new(function(resolve)
		task.delay(seconds, resolve, seconds)
	end)
end

delay(1)
	:next(function(elapsed)
		return elapsed * 2
	end)
	:next(function(doubled)
		print(doubled) -- 2
	end)
	:catch(function(reason)
		warn(reason)
	end)
```

## API

### `Promise.new(executor)`

Creates a promise. The executor receives `resolve` and `reject` and runs in a new thread right away. If it throws, the promise rejects with the thrown value.

- `resolve(value)` fulfills the promise. If `value` is another promise, this promise follows it and settles with the same outcome.
- `reject(reason)` rejects the promise. Reasons can be any value and are passed through unchanged.
- Only the first call to `resolve` or `reject` has any effect.

### `Promise.is(value)`

Returns `true` if `value` is a promise created by this library.

### `promise:next(onFulfilled)`

Returns a new promise that fulfills with the return value of `onFulfilled`. If `onFulfilled` returns a promise, the new promise follows it. If `onFulfilled` throws, or this promise rejects, the new promise rejects with that reason.

### `promise:catch(onRejected)`

Returns a new promise that fulfills with the return value of `onRejected` if this promise rejects. If this promise fulfills, its value passes through unchanged. If `onRejected` throws, the new promise rejects.

### `promise:await()`

Yields the current thread until the promise settles. Returns the value if it fulfilled, and throws the reason if it rejected. It must be called from a thread that can yield.

```lua
local success, result = pcall(delay(1).await, delay(1))

local value = delay(1):await()
```

## Behavior

- Handlers always run in a new thread via `task.spawn`, including handlers attached after the promise has settled.
- Handlers run in the order they were attached.
- A promise resolved with itself rejects.

## Types

The module exports these types:

| Type | Description |
| --- | --- |
| `Promise<T>` | A promise for a value of type `T`. |
| `Status` | `"Pending" \| "Fulfilled" \| "Rejected"` |
| `Executor<T>` | The function passed to `Promise.new`. |
| `Handler<T, U>` | A function passed to `next` or `catch`, returning a `U` or a `Promise<U>`. |

## Not included (TODO)

There is no cancellation, timeout, `finally`, `Promise.all` or `Promise.race`, and no warning for unhandled rejections.
