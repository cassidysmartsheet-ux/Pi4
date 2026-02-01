# Sensitive Configuration

This folder contains configuration files. Some contain sensitive data.

## Files NOT Committed to Git

The following files are gitignored and must be configured locally on each kiosk:

- `network.conf` - WiFi credentials (copy from `network.conf.example`)
- `urls.local.conf` - Override URLs with actual Smartsheet links
- Any file ending in `.local` or `.local.*`

## Safe to Commit

- `kiosk.conf` - Display settings (no secrets)
- `urls.conf` - Template with placeholder URLs
- `network.conf.example` - Template without real credentials
- `*.example` files

## Local Testing

For local development/testing, create:

```bash
# Copy and edit with real values
cp network.conf.example network.conf
```

Then edit `network.conf` with your actual WiFi credentials.

**Never commit real credentials to the repository.**
