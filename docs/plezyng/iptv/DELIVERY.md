# IPTV implementation delivery

This tracker accompanies [PLAN.md](PLAN.md). The plan was prepared against repository revision `0d0626cc375b8fa95124775365a6b37e2a03c9be`; implementation is being reconciled against the current `main` before the feature is considered ready.

## Requested scope

Implement the plan through the point where a provider-issued API key, partner credential, or other external account access is required. Implement generic authentication and secure credential handling for credentials an end user supplies. Leave live partner credentials, proprietary SDK access, external account enrollment, and any provider-specific secret values for the separate handoff. Never commit real keys or sample values that could be mistaken for working credentials.

## Delivery status

| Area | Status |
| --- | --- |
| Existing code branch | `codex/iptv-integration-20261028` has an initial implementation commit; the full plan had not yet been committed with it or opened as a pull request. |
| Plan and requirements | Committed here as `PLAN.md`; this tracker records the API-key boundary. |
| Current-main reconciliation | Pending before further implementation is treated as complete. |
| Generic sources and direct playback | Initial implementation exists; acceptance coverage and platform behavior still need reconciliation against the plan. |
| Provider-key-dependent adapters | Handoff boundary; ship typed interfaces, settings, secure storage and explicit unavailable states without fabricated credentials. |
| Verification | No IPTV-specific tests were present in the implementation branch at handoff. Validation status will be recorded as code work proceeds. |

## Handoff checklist

The follow-on owner should provide the provider's approved API/client key, endpoint and redirect allowlists, test account or sandbox, partner documentation, rate limits, and permitted playback/advertising terms. These values belong in the approved secret-management path and live configuration, never in source, tests, fixtures, screenshots, diagnostics or this repository.
