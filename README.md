# luau-utils

A collection of lightweight, strictly-typed Luau utilities for Roblox.

## Modules

| Module | Description |
| --- | --- |
| [Promise](./promise) | A Promise implementation with chaining, promise adoption and `await`. |

## Installation

Each module is a standalone file with no dependencies. Copy the ones you need into your project, for example under `ReplicatedStorage`, and require them.

## Conventions

- Every module uses `--!strict` and exports its public types.
- Modules have no dependencies on each other unless their README says otherwise.
