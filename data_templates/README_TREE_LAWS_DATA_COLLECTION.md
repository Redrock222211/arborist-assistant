# Victorian LGA Tree Laws Data Collection Template

## 📋 Purpose
This Excel template is for collecting **100% REAL, VERIFIED** tree protection local law data from all 79 Victorian councils.

## 📁 File Location
`/Volumes/d drive/arborist_assistant/data_templates/VICTORIAN_LGA_TREE_LAWS_TEMPLATE.csv`

## ✅ How to Use

### Step 1: Open in Excel
1. Open the CSV file in Microsoft Excel or Google Sheets
2. You'll see all 79 Victorian councils pre-populated
3. Most fields are EMPTY - you need to fill them with REAL data

### Step 2: Visit Council Websites
For each council:
1. Go to their **LOCAL_LAWS_PAGE_URL** (provided)
2. Look for "Tree Protection Local Law" or "Vegetation Local Law"
3. Download the official PDF/document
4. Extract the EXACT information

### Step 3: Fill Out Fields

#### COLUMN DEFINITIONS:

**Basic Info (Pre-filled):**
- `LGA_NAME` - Short council name
- `COUNCIL_FULL_NAME` - Full official name
- `WEBSITE_URL` - Main council website
- `LOCAL_LAWS_PAGE_URL` - Direct link to local laws page
- `PLANNING_PAGE_URL` - Planning department page
- `PHONE` - Council phone number

**Local Law Details (YOU FILL):**
- `LOCAL_LAW_NUMBER` - e.g., "Local Law No. 8"
- `LOCAL_LAW_YEAR` - Year enacted/revised, e.g., "2024"
- `SIZE_THRESHOLD_CIRCUMFERENCE_M` - Trunk circumference threshold in METERS (at 1m height)
- `SIZE_THRESHOLD_HEIGHT_M` - Height threshold in METERS (if applicable)
- `INDIGENOUS_TREES_PROTECTED` - "Yes" or "No" - are indigenous trees protected regardless of size?
- `PRUNING_THRESHOLD_PERCENT` - % of canopy that triggers permit (e.g., "10" for 10%)

**Fees & Processing:**
- `PERMIT_FEE_STANDARD` - Standard permit fee in dollars (e.g., "180.60")
- `PERMIT_FEE_CONCESSION` - Concession fee if applicable
- `PROCESSING_DAYS_MIN` - Minimum processing days (e.g., "28")
- `PROCESSING_DAYS_MAX` - Maximum processing days (e.g., "35")

**Exemptions (Yes/No for each):**
- `EXEMPTION_DEAD_DYING` - Are dead/dying trees exempt?
- `EXEMPTION_EMERGENCY` - Emergency safety works exempt?
- `EXEMPTION_FIRE_PREVENTION` - Fire prevention within X meters of dwelling?
- `EXEMPTION_FRUIT_TREES` - Fruit trees in domestic gardens exempt?
- `OTHER_EXEMPTIONS` - List any other exemptions

**Requirements:**
- `REPLACEMENT_RATIO` - Required replacement ratio (e.g., "2:1" means 2 new trees per 1 removed)
- `ARBORIST_REPORT_REQUIRED` - "Yes" or "No"
- `PENALTIES_MIN` - Minimum penalty in dollars
- `PENALTIES_MAX` - Maximum penalty in dollars

**Verification:**
- `NOTES` - Any special notes or conditions
- `VERIFICATION_STATUS` - Change from "UNVERIFIED" to "VERIFIED" when done
- `VERIFIED_DATE` - Date you verified (YYYY-MM-DD format)
- `VERIFIED_BY` - Your name/initials
- `SOURCE_URL_1` - URL of the actual local law document
- `SOURCE_URL_2` - Additional source if needed

### Step 4: Mark as VERIFIED
When you've filled all fields from official sources:
1. Change `VERIFICATION_STATUS` to "VERIFIED"
2. Add `VERIFIED_DATE` (today's date)
3. Add your name in `VERIFIED_BY`
4. Add the source document URL

## 🔍 Where to Find Data

### Primary Sources:
1. **Council Website** → Local Laws → "Tree Protection" or "Vegetation"
2. **Planning Scheme** → Local Planning Policies
3. **Call the Council** - Phone numbers provided
4. **Email Council** - request latest local law document

### What to Look For in Documents:
- Section about "Trees" or "Vegetation"
- Table of thresholds (circumference, height)
- Fee schedule
- Exemptions list
- Penalties section

## ⚠️ IMPORTANT RULES

### DO:
✅ Use EXACT numbers from official documents
✅ Include source URLs for every entry
✅ Mark date verified
✅ Note if council has NO tree protection local law
✅ Contact council if information unclear

### DON'T:
❌ Guess or estimate ANY values
❌ Copy from other councils
❌ Use outdated information
❌ Leave "VERIFIED" without actual verification
❌ Include your opinions or interpretations

## 📊 Sample Entry (Melbourne)

```csv
Melbourne,"City of Melbourne",https://www.melbourne.vic.gov.au,...,"Local Law No. 2",2019,1.0,,Yes,,,235.00,,21,35,Yes,Yes,No,No,,2:1,Yes,,,Exceptional Tree Register applies,VERIFIED,2024-10-23,John Smith,https://www.melbourne.vic.gov.au/SiteCollectionDocuments/local-law-2.pdf,
```

## 🎯 Priority Councils (Start Here)

### Metropolitan (High Priority):
1. ✅ Whittlesea (partially filled)
2. ✅ Melbourne (partially filled)
3. ⬜ Yarra
4. ⬜ Boroondara
5. ⬜ Glen Eira
6. ⬜ Port Phillip

### Regional (Medium Priority):
1. ⬜ Greater Geelong
2. ⬜ Ballarat
3. ⬜ Greater Bendigo
4. ⬜ Mornington Peninsula

## 📝 Notes

- Some councils may NOT have tree protection local laws (only state planning overlays apply)
- If no local law exists, note "No tree protection local law" in NOTES field
- Fees change annually - verify current year
- Some councils differentiate between "removal" and "pruning" - document both

## 🔄 After Completion

Once filled, save as:
- `VICTORIAN_LGA_TREE_LAWS_VERIFIED_[DATE].csv`

Then we'll import this into the app's database!

## ❓ Questions?

If unclear about any council:
1. Call them directly (numbers provided)
2. Ask for "Tree Protection Local Law information"
3. Request they email you the document
4. Document what they tell you in NOTES field

---

**Good luck with data collection! This will create the most comprehensive Victorian tree law database available!** 🌳
