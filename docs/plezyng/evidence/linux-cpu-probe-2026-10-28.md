# Linux CPU provider probe — 2026-10-28

The PME diagnostic opened the 540p ANVIL-S model through ONNX Runtime's
`CPUExecutionProvider` on `kspls0`. It used one intra-op thread, three warm-ups,
and twelve timed inferences. The run passed `--cpu-only` with `-` as the provider
manifest, so no accelerator provider was attempted.

```json
{
  "provider": "CPUExecutionProvider",
  "vendor": "",
  "device": "CPU",
  "cpu_execution": true,
  "cpu_fallback": false,
  "cpu_only": true,
  "input_elements": 3110400,
  "output_elements": 1555200,
  "warmups": 3,
  "iterations": 12,
  "session_open_ms": 23.568,
  "inference_ms": {
    "median": 317.831,
    "p95": 343.899,
    "mean": 320.096
  }
}
```

The inference median is well above the 41.67 ms interval for a 24 fps source
pair and the 33.33 ms interval for 30 fps. CPU execution is therefore validated
as an explicit diagnostic/runtime option, not as a real-time playback route.
The measurement does not qualify other CPU models or devices.
