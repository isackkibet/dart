# Conflict Resolution Register

| ID | Conflict | Decision | Status |
|---|---|---|---|
| MESH-001 | Imported API could create a second media server | Existing mediasoup remains sole SFU; imported service is control plane only | Resolved |
| MESH-002 | Imported Flutter project duplicated YohPal Live app | Converted to features in canonical streaming package | Resolved |
| MESH-003 | Standalone Next.js Mesh project overlaps root apps | Preserved only as vendor source/reference, not runtime | Resolved |
| MESH-004 | Temporary owner/actor IDs overlap canonical identity | Marked adapter boundary; canonical Firebase/SSO enforcement required | Open before certification |
| MESH-005 | In-memory production/audit state overlaps canonical persistence | Kept as integration seam; replace with canonical repository adapters | Open before certification |
| MESH-006 | Layout state does not yet compose the SFU program output | Contract and UI merged; compositor adapter remains required | Open before certification |
