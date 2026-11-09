# Using a site in an Android WebView

| Where the app runs | URL to load | Needs cleartext? |
|--------------------|-------------|------------------|
| Emulator | `http://10.0.2.2:<PORT>` | yes |
| Real phone, same Wi-Fi | `http://<your-LAN-IP>:<PORT>` (set `BIND=0.0.0.0`) | yes |
| Anywhere | `https://….trycloudflare.com` from `sites tunnel` | **no** |

`10.0.2.2` is the emulator's alias for your computer's `127.0.0.1`, so the default `BIND` works with it.

## Allowing `http://` (dev only)

Android blocks cleartext HTTP by default. The safest way to allow it is a network security config that only permits the dev hosts.

`app/src/main/res/xml/network_security_config.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="false">10.0.2.2</domain>
        <domain includeSubdomains="false">localhost</domain>
    </domain-config>
</network-security-config>
```

`AndroidManifest.xml`:

```xml
<application
    android:networkSecurityConfig="@xml/network_security_config"
    ... >
```

The tunnel URL is HTTPS, so it needs none of this.

## Tip: tunnel URLs change

The URL is new every time you run `sites tunnel`. During development, keep the base URL somewhere easy to change, such as a `BuildConfig` field or `local.properties`, so you don't have to edit code each time.
