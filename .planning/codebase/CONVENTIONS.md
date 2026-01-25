# Coding Conventions

**Analysis Date:** 2026-01-25

## Naming Patterns

**Files:**
- PascalCase for types and protocols (e.g., `TransportService.swift`, `TransportMapView.swift`)
- Descriptive names that clearly indicate purpose

**Functions:**
- camelCase starting with verb (e.g., `queryNearbyStops()`, `loadDepartures()`)
- Descriptive names explaining what they do

**Variables:**
- camelCase (e.g., `selectedStop`, `cameraPosition`)
- Use descriptive names, avoid abbreviations

**Types:**
- PascalCase for structs, classes, enums (e.g., `TransportStop`, `TransportError`)
- Use meaningful names that describe the domain concept

## Code Style

**Formatting:**
- Not detected - No SwiftFormat or similar tool configured
- Code appears manually formatted with consistent indentation

**Linting:**
- Not detected - No SwiftLint configuration found
- Some linting rules from dependencies found in build directory

## Import Organization

**Order:**
1. System frameworks (SwiftUI, Foundation, CoreLocation, etc.)
2. External dependencies (TripKit)
3. Local modules (none currently)

**Path Aliases:**
- Not configured - using relative imports

## Error Handling

**Patterns:**
- Use Swift's `do/try/catch` for throwing functions
- Custom error enums with `LocalizedError` conformance (e.g., `TransportError`)
- Early returns with `guard let` for optionals
- Task cancellation checks with `try Task.checkCancellation()`

## Logging

**Framework:** Console logging only (print statements not observed in code)

**Patterns:**
- No structured logging framework detected
- Error messages through `LocalizedError.errorDescription`

## Comments

**When to Comment:**
- MARK: comments for code organization sections
- Brief comments for complex business logic
- Doc comments not extensively used

**JSDoc/TSDoc:**
- Not used - Swift uses /// for documentation comments (not observed)

## Function Design

**Size:** Functions are reasonably sized, largest observed around 50-60 lines in complex view logic

**Parameters:** 
- Use descriptive parameter names
- Default values for optional parameters (e.g., `maxDistance: Int = 2000`)

**Return Values:** 
- Prefer concrete types over Any
- Use Result types implicitly through throws
- Optional returns for failable initializers

## Module Design

**Exports:** All public types and functions are properly scoped

**Barrel Files:** Not applicable (single target)

---

*Convention analysis: 2026-01-25*