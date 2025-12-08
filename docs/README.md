# ReactiveNotifier Documentation

## Overview

ReactiveNotifier is a lightweight, singleton-based state management solution for Flutter following the **"Create Once, Reuse Always"** philosophy.

**Current Version**: 2.13.0

## Documentation Index

### Getting Started
- [Quick Start Guide](getting-started/quick-start.md) - Get up and running in minutes

### Architecture
- [Architecture Overview](architecture/overview.md) - Complete system architecture with diagrams and design decisions

### Core Features
- [ReactiveNotifier<T>](features/reactive-notifier.md) - Core state holder class
- [ViewModel<T>](features/viewmodel.md) - Complex state with synchronous initialization
- [AsyncViewModelImpl<T>](features/async-viewmodel.md) - Async operations with loading/success/error states
- [State Types](features/state-types.md) - AsyncState and StreamState reference
- [Builder Widgets](features/builders.md) - ReactiveBuilder, ReactiveViewModelBuilder, ReactiveAsyncBuilder, and more

### Advanced Features
- [Related States](features/related-states.md) - Parent-child state relationships with automatic propagation
- [Auto-Dispose](features/auto-dispose.md) - Widget-aware lifecycle with automatic memory cleanup
- [Context Access](features/context-access.md) - BuildContext access in ViewModels
- [Communication](features/communication.md) - Cross-service communication with listen/listenVM
- [Hooks](features/hooks.md) - State change hooks (onStateChanged, onAsyncStateChanged)

### Testing
- [Testing Guide](features/testing.md) - Complete testing patterns and utilities

### Legacy Guides
- [Context Pattern](guides/context-pattern.md) - BuildContext migration patterns
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

### State Types

| State | Use Case |
|-------|----------|
| `AsyncState<T>` | Async operations (initial/loading/success/error/empty) |
| `StreamState<T>` | Stream operations (initial/loading/data/error/done) |

## API Reference

For complete API reference and AI/development context, see [CLAUDE.md](../CLAUDE.md) in the project root.

## Version History

See [CHANGELOG.md](../CHANGELOG.md) for detailed version history.
