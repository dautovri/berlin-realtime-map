---
created: 2026-01-25T23:39:54Z
title: Verify Xcode CLI build succeeds
area: general
files:
  - BerlinTransportMap.xcodeproj
---

## Problem

The project should build successfully using Xcode command line tools to ensure all Swift implementations are syntactically correct and linked properly, as part of integration verification.

## Solution

Run `xcodebuild -workspace BerlinTransportMap.xcworkspace -scheme BerlinTransportMap -sdk iphonesimulator -configuration Debug build` and verify BUILD SUCCEEDED.