# iOS Info.plist Final Example

This is a merge example only. Do not replace the full existing file blindly.

```xml
<key>NSCameraUsageDescription</key>
<string>YohPal Live needs camera access so you can broadcast live video.</string>

<key>NSMicrophoneUsageDescription</key>
<string>YohPal Live needs microphone access so viewers can hear your live stream.</string>

<key>NSLocalNetworkUsageDescription</key>
<string>YohPal Live needs local network access to connect to the local streaming server during development testing.</string>

<key>NSBonjourServices</key>
<array/>
```

Debug-only ATS exception, if absolutely needed:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>192.168.1.10</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
            <false/>
            <key>NSTemporaryExceptionMinimumTLSVersion</key>
            <string>TLSv1.2</string>
        </dict>
    </dict>
</dict>
```
