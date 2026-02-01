# Smartsheet Publishing Guide

How to publish and optimize Smartsheet content for the kiosk displays.

## Overview

Smartsheet offers several publishing options. For kiosk displays, we use **Published Views** which create read-only URLs that update automatically when the source data changes.

## KNOWN ISSUES

Before proceeding, be aware of these Smartsheet limitations:

### 1. Calendar View May Not Persist

**Problem:** When you publish a sheet that's set to Calendar view, the published URL may load as Grid view instead.

**Workarounds:**
- Re-publish while actively viewing the Calendar (toggle publish off, switch to Calendar, toggle back on)
- Use a **Dashboard** with an embedded Calendar widget (more reliable)
- Accept Grid view if Calendar doesn't stick

### 2. Heavy JavaScript Load

**Problem:** Published views load 5-10MB of JavaScript and require significant processing power.

**Impact:**
- Pi 2, Pi 3, Firestick will **timeout and fail**
- Pi 4 (4GB) is **required** for reliable operation
- Initial page load takes 30-60 seconds

### 3. No Font Size Control

**Problem:** You cannot increase font size in published views for better readability on large screens.

**Workarounds:**
- Use browser zoom (configured in `kiosk.conf`)
- Design sheets with fewer columns so text appears larger
- Use Dashboards with Metric widgets for key numbers

---

## Publishing a Sheet

### Step-by-Step

1. Open your sheet in Smartsheet
2. Click **File** in the top menu
3. Click **Publish**
4. Toggle **Read-Only - Full** to ON
5. Copy the generated URL

### Publish Settings

| Option | Description | Recommended |
|--------|-------------|-------------|
| Read-Only - Full | Shows entire sheet, allows scroll | ✅ Best for schedules |
| Read-Only - Rows Only | Removes attachments/comments | Use if sheet has many attachments |
| Edit - Secure | Requires login to edit | Not for kiosk |
| iCal | Calendar format export | Not for kiosk |

### URL Format

Published URLs look like:
```
https://app.smartsheet.com/b/publish?EQBCT=abc123def456
```

The code after `EQBCT=` is unique to your published view.

---

## Publishing a Report

Reports can aggregate data from multiple sheets and are often better for displays.

### Creating a Display-Optimized Report

1. **File** > **Create** > **Create Report**
2. Add source sheets
3. Filter for relevant data:
   - Current week only
   - Specific crew
   - Active jobs
4. Choose columns to display
5. Set sorting (by date recommended)
6. **File** > **Publish**

### Report Advantages

- Combine multiple sheets
- Filter dynamically
- Show summary views
- Auto-update from sources

---

## Publishing a Dashboard

Dashboards provide the best visual experience for large displays.

### Dashboard Widgets for Kiosks

| Widget | Good For |
|--------|----------|
| Sheet/Report | Schedule details |
| Chart | Visual status |
| Metric | Key numbers |
| Title | Headers/labels |
| Image | Logos, icons |

### Dashboard Design Tips

1. **Large fonts** - Viewers are 10+ feet away
2. **High contrast** - Dark text on light background (or vice versa)
3. **Minimal scroll** - Fit key info on one screen
4. **Bold colors** - For status indicators

### Publishing a Dashboard

1. Open the dashboard
2. Click **Share** (top right)
3. Click **Publish** tab
4. Toggle **Anyone with the link** to ON
5. Click **Options**:
   - ✅ Allow viewers to refresh
   - ❌ Show toolbar (hide for cleaner look)
6. Copy the URL

---

## Auto-Refresh Behavior

### Smartsheet Refresh

Published views auto-refresh approximately every **5 minutes**.

This is controlled by Smartsheet, not the kiosk.

### Kiosk Refresh

The kiosk adds an additional hard refresh every 5 minutes (configurable) as a backup.

### Forcing Immediate Update

When you update data in Smartsheet:

1. Changes save immediately to the sheet
2. Published view updates within ~5 minutes
3. Kiosk displays the updated view

**To force faster update:**
1. In Smartsheet, re-publish (toggle off/on)
2. Or on kiosk: `/opt/kiosk/scripts/refresh.sh --hard`

---

## Optimizing for Display

### Column Considerations

**Show:**
- Job Name/Address
- Date/Time
- Crew assignments
- Status

**Hide:**
- Internal notes
- Cost data
- Customer contact info (privacy)
- System columns (Created By, etc.)

### Formatting for Readability

1. **Increase row height** for larger text display
2. **Use conditional formatting** for status colors:
   - Green = Completed
   - Yellow = In Progress
   - Red = Delayed
3. **Freeze header row** for context during scroll

### Calendar View Optimization

If using Calendar view:

1. Use Week view (not Month) for readability
2. Enable "Show additional fields" for key data
3. Color-code by crew or job type

---

## Multiple Views Per Crew

You can configure URL rotation for multiple views:

### Example Setup

In `/opt/kiosk/config/urls.conf`:

```ini
# Crew 1 Primary - Weekly Schedule
CREW1_URL="https://app.smartsheet.com/b/publish?EQBCT=schedule123"

# Crew 1 Secondary - Equipment Dashboard
CREW1_URL_2="https://app.smartsheet.com/b/publish?EQBCT=equipment456"

# Crew 1 Tertiary - Company Announcements
CREW1_URL_3="https://app.smartsheet.com/b/publish?EQBCT=announce789"
```

In `/opt/kiosk/config/kiosk.conf`:

```ini
# Rotate every 60 seconds
URL_ROTATION_INTERVAL=60

# Include all three URLs
URL_ROTATION_SOURCES="all"
```

---

## Smartsheet Permissions

### Who Can Publish

- Sheet owners
- Admins with sharing rights
- Users with "Admin" permission level

### Published Link Security

Published links are "security by obscurity":
- Anyone with the URL can view
- URLs are long random strings
- Not indexed by search engines
- Can be revoked anytime

### Revoking Access

If a published URL is compromised:

1. Open the sheet/report/dashboard
2. **File** > **Publish** (or **Share** > **Publish**)
3. Toggle the publish option OFF
4. Re-enable to generate a NEW URL
5. Update the kiosk configuration with the new URL

---

## Common Issues

### Published View Shows Old Data

**Cause:** Caching delay

**Solutions:**
1. Wait 5 minutes for auto-refresh
2. Hard refresh kiosk: `/opt/kiosk/scripts/refresh.sh --hard`
3. Re-publish in Smartsheet

### Published Link Stopped Working

**Causes:**
- Publishing was disabled
- Sheet was deleted
- Sheet was moved
- Permissions changed

**Solutions:**
1. Check sheet exists and you have access
2. Re-publish and get new URL
3. Update kiosk configuration

### Dashboard Widgets Not Loading

**Cause:** Individual widgets have separate permissions

**Solution:**
- Ensure underlying sheets/reports are shared with "Anyone with link"
- Or, make them part of the dashboard's data sources

### View Requires Login

**Cause:** Published as "secure" view

**Solution:**
- Publish as "Read-Only - Full" (unsecured)
- Kiosks cannot handle login prompts

---

## Best Practices Summary

1. ✅ Use Reports for filtered, crew-specific views
2. ✅ Use Dashboards for visual layouts
3. ✅ Keep published URLs confidential
4. ✅ Hide sensitive columns before publishing
5. ✅ Test published view in incognito browser
6. ✅ Document which URLs go to which kiosk
7. ❌ Don't publish financial/personal data
8. ❌ Don't use "secure" publish options for kiosks
9. ❌ Don't embed the URL in public places

---

## Reference

### Smartsheet Documentation

- [Publishing Sheets](https://help.smartsheet.com/articles/522063-publishing-sheets)
- [Publishing Reports](https://help.smartsheet.com/articles/2479676-publishing-reports)
- [Publishing Dashboards](https://help.smartsheet.com/articles/2482506-publishing-sights-dashboards)

### URL Structure

```
https://app.smartsheet.com/b/publish?EQBCT=<unique-code>
```

- Base: `app.smartsheet.com`
- Path: `/b/publish`
- Parameter: `EQBCT` = published content ID
