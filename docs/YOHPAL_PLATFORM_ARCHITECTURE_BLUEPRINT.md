# YohPal Platform Architecture Blueprint

## Platform Layer
```
lib/platform/
├── identity/
├── wallet/
├── notifications/
├── search/
├── brain/
├── analytics/
├── routing/
├── deep_links/
├── floating/
├── mission_control/
├── os/
└── migration/
```

## Shared Services
- YohPalIdentityService
- YohPalWalletService
- YohPalNotificationService
- YohPalSearchService
- YohPalBrainGateway
- YohPalAnalyticsService
- YohPalDeepLinkService

## Integration Rule
Every module consumes shared platform services via `YohPalPlatformProvider.of(context)`.

## Deep Links
- yohpal://live/creator/123
- yohpal://jobs/job/987
- yohpal://hustle/provider/22
- yohpal://market/product/44
- yohpal://wallet
- yohpal://ycios/project/55
