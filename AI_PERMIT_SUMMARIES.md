# AI-Powered Permit Summaries

## Overview
Instead of maintaining a static database of permit requirements (which can become outdated), this app uses **Google Gemini AI** to automatically interpret Victorian planning overlays and generate accurate, up-to-date permit summaries.

## How It Works

1. **Real Data**: The app queries the official Victorian Planning MapShare API to get:
   - Planning overlays (VPO2, HO, ESO, etc.)
   - Planning zones (GRZ1, NRZ, etc.)
   - LGA information

2. **AI Interpretation**: Google Gemini AI analyzes the overlay codes and generates:
   - Specific permit requirements (e.g., "VPO2: Permit required to remove trees DBH > 20cm")
   - Exemptions (dead/dying trees, emergency works)
   - Required documents (arborist reports, site plans)
   - Processing information

3. **Always Current**: Since the AI interprets the latest planning data, summaries are always accurate

## Setup (Free!)

### Step 1: Get a Free Gemini API Key
1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the generated key

### Step 2: Add Your API Key
1. Open `lib/config/ai_config.dart`
2. Replace `'YOUR_GEMINI_API_KEY_HERE'` with your actual key:
   ```dart
   static const String geminiApiKey = 'AIzaSy...your-key-here';
   ```
3. Save the file
4. Restart the app

### Step 3: Test It
1. Click "Tree Permits" button
2. Search for an address (e.g., "123 Main St, Epping VIC")
3. The AI will generate a summary with specific permit requirements

## Example Output

**Without AI** (static database):
```
VPO2: Vegetation Protection Overlay - Schedule 2
Contact council for details.
```

**With AI** (intelligent summary):
```
VPO2 - VEGETATION PROTECTION OVERLAY SCHEDULE 2:

PERMIT REQUIRED TO:
• Remove trees with DBH > 20cm (measured at 1.4m)
• Prune limbs > 10cm diameter
• Remove any indigenous/native vegetation

EXEMPTIONS:
• Dead/dying/dangerous trees (arborist certification required)
• Branches < 10cm diameter
• Emergency works

REQUIREMENTS:
• Arborist report (AS4970 compliant)
• Replacement planting plan (typically 2:1 ratio)
• Tree protection zones during construction
```

## Cost
- **Free tier**: 15 requests per minute, 1500 requests per day
- More than enough for typical usage
- No credit card required

## Privacy
- Only planning overlay codes and LGA names are sent to Google
- No personal information or addresses are shared
- Summaries are generated in real-time, not stored by Google

## Fallback
If AI is not configured or fails:
- The app shows the raw overlay data from VicPlan
- Advises users to contact the council
- Still works, just less detailed

## Benefits
1. ✅ **Always accurate** - No outdated static database
2. ✅ **Detailed** - Specific DBH, height, and circumference thresholds
3. ✅ **Contextual** - Interprets schedules and local variations
4. ✅ **Free** - Google Gemini free tier is generous
5. ✅ **Automatic** - No manual database maintenance needed
