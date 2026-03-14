# ReactiveNotifier Documentation

## Overview

ReactiveNotifier is a lightweight, singleton-based state management solution for Flutter following the **"Create Once, Reuse Always"** philosophy.

**Current Version**: 2.17.0-beta.2

## Core Components

ReactiveNotifier offers three core components for different use cases:

- **`ReactiveNotifier<T>`** - Simple state values (primitives, settings, flags)
- **`ViewModel<T>`** - Complex state with synchronous initialization and business logic
- **`AsyncViewModelImpl<T>`** - Async operations with loading/success/error states

### When to Use Which Component

| Component | Purpose | Use Cases |
|-----------|---------|-----------|
| `ReactiveNotifier<T>` | Simple primitive state | Counters, flags, settings, theme toggles |
| `ViewModel<T>` | Complex synchronous state  | Form validation, business logic, cross-VM communication |
| `AsyncViewModelImpl<T>` | Async operations | API calls, database queries, file I/O |

For detailed guidance on choosing the right component, see the [Quick Reference](#quick-reference) section below.

## Documentation Index

### Getting Started

- [Quick Start Guide](getting-started/quick-start.md) - Get up and running in minutes

### Architecture

- [Architecture Overview](architecture/overview.md) - Complete system architecture with diagrams and design decisions

### Core Features

#### State Management

- [ReactiveNotifier<T>](features/reactive-notifier.md) - Core state holder class
- [ViewModel<T>](features/viewmodel.md) - Complex state with synchronous initialization
- [AsyncViewModelImpl<T>](features/async-viewmodel.md) - Async operations with loading/success/error states
- [State Types](features/state-types.md) - AsyncState and StreamState reference

#### Builder Widgets

- [Builder Widgets Overview](features/builders.md) - All builders reference
- [ReactiveContextBuilder](features/builders/reactive-context-builder.md) - Force InheritedWidget strategy

#### Context Access System

- [Context Access Overview](features/context-access.md) - BuildContext access in ViewModels
  - [context](features/context/context.md) - Nullable context getter
  - [hasContext](features/context/has-context.md) - Check context availability
  - [requireContext()](features/context/require-context.md) - Required context with errors
  - [globalContext](features/context/global-context.md) - Direct global context access
  - [hasGlobalContext](features/context/has-global-context.md) - Check global context availability
  - [requireGlobalContext()](features/context/require-global-context.md) - Required global context
  - [initContext()](features/context/init-context.md) - Global context initialization
  - [waitForContext](features/context/wait-for-context.md) - AsyncViewModel context parameter

### Advanced Features

- [Related States](features/related-states.md) - Parent-child state relationships with automatic propagation
- [Auto-Dispose](features/auto-dispose.md) - Widget-aware lifecycle with automatic memory cleanup
- [Communication](features/communication.md) - Cross-service communication with listen/listenVM
- [Hooks](features/hooks.md) - State change hooks (onStateChanged, onAsyncStateChanged)
- [onDependenciesStateChanged](features/viewmodel/on-dependencies-state-changed.md) - Declarative dependency tracking with batching
- [call() Syntax](features/call-syntax.md) - Shorthand data access on ReactiveNotifier

### Testing

- [Testing Guide](features/testing.md) - Complete testing patterns and utilities

### Guides

- [Context Pattern Guide](guides/context-pattern.md) - BuildContext migration patterns and best practices
- [Reactive Context](guides/reactive-context.md) - Reactive context management
- [Memory Management](guides/memory-management.md) - Listener tracking and leak prevention
- [Dispose and Recreation](guides/dispose-and-recreation.md) - ViewModel lifecycle patterns

## Quick Reference

### Core Components

| Component | Purpose | Use When |
|-----------|---------|----------|
| `ReactiveNotifier<T>` | Simple state values | Primitives, settings, flags |
| `ViewModel<T>` | Complex state + business logic | Validation, sync initialization |
| `AsyncViewModelImpl<T>` | Async operations | API calls, database ops |

### Builder Components

| Builder | Use Case |
|---------|----------|
| `ReactiveBuilder<T>` | Simple state values |
| `ReactiveViewModelBuilder<VM, T>` | Custom ViewModels |
| `ReactiveAsyncBuilder<VM, T>` | Async states with loading/error |
| `ReactiveStreamBuilder<VM, T>` | Real-time streams |
| `ReactiveFutureBuilder<T>` | One-time futures |
| `ReactiveContextBuilder` | Force InheritedWidget strategy |

### Context Access

| Property/Method | Description |
|-----------------|-------------|
| `context` | Nullable context (falls back to global) |
| `hasContext` | Check any context available |
| `requireContext()` | Required context with errors |
| `globalContext` | Direct global context access |
| `hasGlobalContext` | Check global context available |
| `requireGlobalContext()` | Required global context |
| `ReactiveNotifier.initContext()` | Initialize global context |
| `waitForContext` | Wait for context in AsyncViewModel |

### State Types

| State | Use Case |
|-------|----------|
| `AsyncState<T>` | Async operations (initial/loading/success/error/empty) |
| `StreamState<T>` | Stream operations (initial/loading/data/error/done) |

## API Reference

For complete API reference and AI/development context, see [CLAUDE.md](../CLAUDE.md) in the project root.

## Version History

See [CHANGELOG.md](../CHANGELOG.md) for detailed version history.

## Document Structure

```
docs/
├── README.md                           # This file
├── getting-started/
│   └── quick-start.md
├── architecture/
│   └── overview.md
├── features/
│   ├── reactive-notifier.md
│   ├── viewmodel.md
│   ├── viewmodel/                      # ViewModel API reference
│   │   ├── init.md
│   │   ├── data.md
│   │   ├── update-state.md
│   │   └── ...
│   ├── async-viewmodel.md
│   ├── async-viewmodel/                # AsyncViewModel API reference
│   │   ├── constructor.md
│   │   ├── loading-state.md
│   │   └── ...
│   ├── builders.md
│   ├── builders/                       # Builder widgets
│   │   └── reactive-context-builder.md
│   ├── context-access.md               # Context system overview
│   ├── context/                        # Context API reference
│   │   ├── context.md
│   │   ├── has-context.md
│   │   ├── require-context.md
│   │   ├── global-context.md
│   │   ├── has-global-context.md
│   │   ├── require-global-context.md
│   │   ├── init-context.md
│   │   └── wait-for-context.md
│   ├── state-types.md
│   ├── related-states.md
│   ├── auto-dispose.md
│   ├── communication.md
│   ├── hooks.md
│   └── testing.md
├── guides/
│   ├── context-pattern.md
│   ├── reactive-context.md
│   ├── memory-management.md
│   └── dispose-and-recreation.md
└── testing/
    └── testing-guide.md
```
