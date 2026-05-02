#!/usr/bin/env bash
# scripts/validate-city-endpoints.sh
#
# Per-city HAFAS endpoint health probe. Validates each CityConfig's
# /locations/nearby + /stops/{id}/departures endpoints against the live
# v6.db.transport.rest / v6.vbb.transport.rest backend.
#
# Use case: before flipping a city's `supportsDepartures` flag from false → true,
# run this to confirm the backend has actually recovered. Or run periodically to
# detect regressions in live cities.
#
# Output:
#   For each city: ✓ healthy / ⚠ partial / ✗ broken (with sample stop + line)
#   Summary line listing which cities should have supportsDepartures=true.
#
# Usage:
#   ./scripts/validate-city-endpoints.sh             # probe all cities
#   ./scripts/validate-city-endpoints.sh stuttgart   # probe one city by id
#
# Requires: python3, network. Sleeps 2s between cities to be nice to the
# community-maintained API.

set -e
cd "$(dirname "$0")/.."

ONLY_CITY="${1:-}"

python3 <<'PY'
import json, os, re, sys, time, urllib.request, urllib.parse

ONLY = os.environ.get("ONLY_CITY", "")

with open("BerlinTransportMap/Models/CityConfig.swift") as f:
    src = f.read()

pattern = re.compile(
    r'static let \w+ = CityConfig\(\s*'
    r'id: "([^"]+)",\s*name: "([^"]+)",\s*'
    r'transitAuthority: "([^"]+)",\s*apiBaseURL: "([^"]+)",\s*'
    r'centerLatitude: ([\d.]+),\s*centerLongitude: ([\d.]+)', re.DOTALL)
cities = []
for m in pattern.finditer(src):
    cid = m.group(1)
    if ONLY and cid != ONLY:
        continue
    cities.append({
        "id": cid, "name": m.group(2), "auth": m.group(3),
        "url": m.group(4), "lat": float(m.group(5)), "lon": float(m.group(6)),
    })

H = {"User-Agent": "Berlin-Transit-Map/validate-endpoints"}

def probe(c):
    nearby = f"{c['url']}/locations/nearby?latitude={c['lat']}&longitude={c['lon']}&distance=2000&results=10&type=station"
    try:
        with urllib.request.urlopen(urllib.request.Request(nearby, headers=H), timeout=20) as r:
            stops = json.loads(r.read().decode())
    except Exception as e:
        return ("BROKEN", f"nearby unreachable: {type(e).__name__}: {str(e)[:60]}")
    candidates = [s for s in stops if s.get("id")][:5]
    if not candidates:
        return ("BROKEN", "nearby returned no stations with ids")

    tried = ok = 0
    first_ok = None
    last_err = None
    for stop in candidates:
        time.sleep(1.5)
        tried += 1
        sid = urllib.parse.quote(str(stop["id"]), safe="")
        dep = f"{c['url']}/stops/{sid}/departures?duration=20&results=3"
        try:
            with urllib.request.urlopen(urllib.request.Request(dep, headers=H), timeout=20) as r:
                data = json.loads(r.read().decode())
            ok += 1
            if not first_ok:
                deps = data.get("departures", []) if isinstance(data, dict) else (data if isinstance(data, list) else [])
                if deps:
                    line = (deps[0].get("line") or {}).get("name", "?")
                    first_ok = f"{stop['name'][:30]} → {line}"
                else:
                    first_ok = f"{stop['name'][:30]} (200, no live deps)"
        except urllib.error.HTTPError as e:
            last_err = f"HTTP {e.code} on {stop['id']}"
        except Exception as e:
            last_err = f"{type(e).__name__}"

    if ok == tried:
        return ("HEALTHY", f"{ok}/{tried} → {first_ok}")
    if ok > 0:
        return ("PARTIAL", f"{ok}/{tried} → first ok: {first_ok}; last err: {last_err}")
    return ("BROKEN", f"0/{tried} → {last_err}")

print(f"\n{'CITY':<12} {'AUTH':<8} {'STATUS':<10} DETAIL")
print("-" * 110)
results = []
for c in cities:
    time.sleep(2)
    status, detail = probe(c)
    icon = {"HEALTHY":"✓", "PARTIAL":"⚠", "BROKEN":"✗"}[status]
    print(f"{c['name']:<12} {c['auth']:<8} {icon} {status:<8} {detail}")
    results.append((c, status, detail))

print()
healthy = [c["id"] for c, s, _ in results if s == "HEALTHY"]
partial = [c["id"] for c, s, _ in results if s == "PARTIAL"]
broken  = [c["id"] for c, s, _ in results if s == "BROKEN"]
print(f"=== HEALTHY: {len(healthy)} | PARTIAL: {len(partial)} | BROKEN: {len(broken)} ===")
print()
print("Recommendation:")
print(f"  supportsDepartures=true  → {', '.join(healthy + partial) or '(none)'}")
print(f"  supportsDepartures=false → {', '.join(broken) or '(none)'}")
print()
print("Compare against current CityConfig.swift values; flip flags as needed.")
print("Re-run weekly during distribution sprint to catch backend regressions.")

if broken:
    sys.exit(1)
PY
