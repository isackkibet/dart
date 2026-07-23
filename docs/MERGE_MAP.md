# YohPal Live Merge Map
## Blueprint to Implementation Mapping
| Blueprint Name | Implemented Name | Decision |
|---|---|---|
| replay_factory | clip_factory | Accepted mapping |
| replayFactory | clip-factory | Accepted mapping |
| social_connectors | social_connector | Accepted mapping |
| media_provider / stream_key | pipeline_config / media_job | Accepted mapping |
| TypeScript FFmpeg worker | Python FFmpeg worker | Accepted implementation deviation |
## Rule
Do not rename working modules before production unless a real runtime defect exists.
Document deviations here instead.
