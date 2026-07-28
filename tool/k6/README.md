# Innovator k6 capacity tests

## 1) Signup + API ramp (realistic new-user mix)

```powershell
& "C:\Program Files\k6\k6.exe" run tool/k6/innovator_load.js -e PROFILE=ramp
```

## 2) Pre-login pool (pure feed/API ceiling)

Creates tokens in `setup()`, then ramps VUs without mass registration:

```powershell
& "C:\Program Files\k6\k6.exe" run tool/k6/innovator_load_pool.js -e POOL=25 -e MAX_VUS=200
```

## Latest results (approx.)

| Scenario | Comfortable concurrent | Notes |
|----------|------------------------|-------|
| With signup bursts | ~70 | Auth `/register` bottlenecks first |
| Pre-login API mix | ~90 | Connection errors rise past ~100 |
| 200 VUs | Not sustainable | ~13% fail rate |

Outputs: `last_summary.json`, `last_pool_summary.json`
