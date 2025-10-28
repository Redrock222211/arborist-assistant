# Victorian Planning Overlays - Tree Requirements Data Collection

## 📋 Purpose
Collect **VERIFIED** tree protection requirements for Victorian Planning Scheme OVERLAYS and their SCHEDULES.

## 🎯 The Challenge

Planning overlays work differently than local laws:
- **VPO (Vegetation Protection Overlay)** can have 10+ different schedules
- **Each schedule has DIFFERENT requirements** in different councils
- Example: VPO2 in Whittlesea ≠ VPO2 in Melbourne

## 📁 File Location
`/Volumes/d drive/arborist_assistant/data_templates/VICTORIAN_OVERLAYS_TREE_REQUIREMENTS_TEMPLATE.csv`

## 🔍 Where to Find Overlay Data

### Primary Source: Planning Scheme Maps
1. **VicPlan Online:** https://planning-schemes.app.planning.vic.gov.au/
2. Navigate to specific council (e.g., "Whittlesea Planning Scheme")
3. Click **"Overlays"** in the menu
4. Find the overlay (e.g., "Clause 42.02 - VPO")
5. Read the **Schedule** (e.g., "Schedule 2 to Clause 42.02")

### How to Navigate VicPlan:
```
1. Go to https://planning-schemes.app.planning.vic.gov.au/
2. Select Council (e.g., "Whittlesea")
3. Go to "Planning Scheme" → "Ordinance"
4. Click "Overlays" section (Clause 42.XX)
5. Find specific overlay (e.g., 42.02 = VPO)
6. Read all schedules (Schedule 1, 2, 3, etc.)
```

## 📊 Column Definitions

### Basic Identification:
- `OVERLAY_CODE` - VPO, ESO, HO, SLO, BMO, etc.
- `SCHEDULE_NUMBER` - 1, 2, 3, etc.
- `LGA_NAME` - Which council (can be multiple councils with same schedule)
- `OVERLAY_FULL_NAME` - Full official name

### Tree Size Thresholds:
- `TREE_SIZE_THRESHOLD_DBH_CM` - Diameter at Breast Height in CENTIMETERS (e.g., "20")
- `TREE_SIZE_THRESHOLD_HEIGHT_M` - Height threshold in METERS
- `TREE_SIZE_THRESHOLD_CIRCUMFERENCE_M` - Trunk circumference in METERS (at 1m height)
- `INDIGENOUS_TREES_PROTECTED` - Yes/No - protected regardless of size?
- `SIGNIFICANT_TREES_PROTECTED` - Yes/No - listed/significant trees protected?

### Permit Requirements:
- `PRUNING_PERMIT_REQUIRED` - Yes/No
- `PRUNING_THRESHOLD_DESCRIPTION` - e.g., "Limbs > 10cm diameter" or "> 10% canopy"
- `REMOVAL_PERMIT_REQUIRED` - Yes/No

### Exemptions:
- `EXEMPTION_DEAD_DYING` - Yes/No (usually requires arborist report)
- `EXEMPTION_EMERGENCY` - Yes/No (emergency dangerous tree works)
- `EXEMPTION_FIRE_PREVENTION_10M` - Yes/No (within 10m of dwelling)
- `EXEMPTION_NOXIOUS_WEEDS` - Yes/No
- `OTHER_EXEMPTIONS` - List any other specific exemptions

### Requirements:
- `ARBORIST_REPORT_REQUIRED` - Yes/No
- `OFFSET_REQUIRED` - Yes/No (native vegetation offsets)
- `OFFSET_RATIO` - e.g., "2:1", "5:1", "10:1"
- `REPLACEMENT_PLANTING_REQUIRED` - Yes/No

### Process:
- `TYPICAL_PERMIT_FEE` - Average fee (varies by council)
- `TYPICAL_PROCESSING_DAYS` - e.g., "28-60"
- `PENALTIES_DESCRIPTION` - Penalty range or description
- `COUNCIL_REFERRAL` - Council/DELWP/Both
- `DELWP_REFERRAL` - Yes/No (referred to state government?)

### Verification:
- `NOTES` - Important specifics or variations
- `VERIFICATION_STATUS` - UNVERIFIED / VERIFIED / NO_TREE_REQUIREMENTS
- `VERIFIED_DATE` - YYYY-MM-DD
- `VERIFIED_BY` - Your name
- `SOURCE_VPP_URL` - Link to VicPlan page
- `SOURCE_COUNCIL_SCHEDULE_URL` - Direct link to schedule document

## 📝 Step-by-Step Process

### For Each Overlay Type (VPO, ESO, HO, etc.):

1. **Go to VicPlan website**
2. **Select a council** (start with Whittlesea, Melbourne, Yarra)
3. **Navigate to Overlays section**
4. **Find the specific clause:**
   - VPO = Clause 42.02
   - ESO = Clause 42.01
   - SLO = Clause 42.03
   - HO = Clause 43.01
   - BMO = Clause 44.06
   - DDO = Clause 43.02
   - DCPO = Clause 45.06

5. **Read EACH schedule** (Schedule 1, 2, 3...)
6. **Look for tree-specific requirements:**
   - "Permit required to..."
   - "Native vegetation..."
   - "Trees with..."
   - "Exemptions include..."

7. **Fill in the spreadsheet row**
8. **Add source URL**

### Example: VPO2 in Whittlesea

```
Search for: "Whittlesea Planning Scheme"
→ Overlays
→ Clause 42.02 (VPO)
→ Schedule 2

Look for sections like:
- "A permit is required to remove, destroy or lop native vegetation"
- "Exemptions: dead or dying vegetation..."
- "Trees with trunk diameter > 20cm..."

Fill in spreadsheet with EXACT wording and measurements.
```

## ⚠️ Common Overlay Types for Trees

### HIGH PRIORITY (Start with these):

**VPO - Vegetation Protection Overlay**
- Most direct tree protection
- Usually has specific size thresholds
- Native vegetation focus
- Offset requirements common

**ESO - Environmental Significance Overlay**
- Waterways, habitat areas
- Often protects riparian vegetation
- Environmental assessments required

**SLO - Significant Landscape Overlay**
- Scenic areas, ridgelines
- Landscape character protection
- May have tree height/canopy requirements

**HO - Heritage Overlay**
- Heritage significant trees
- Often ALL trees protected on heritage sites
- Special permit requirements

### MEDIUM PRIORITY:

**BMO - Bushfire Management Overlay**
- May REQUIRE tree removal
- Defendable space requirements
- Vegetation clearance rules

**DDO - Design and Development Overlay**
- May include tree retention requirements
- Varies greatly by schedule

**DCPO - Development Contributions Plan**
- Usually infrastructure levies
- Rarely tree-specific (but check)

### LOW PRIORITY (Usually no tree requirements):
- EAO, LSIO, FO, PAO, SCO, SBO - Check but usually not tree-focused

## 🎯 Sample Completed Entry

### VPO2 - Whittlesea (Verified Example):

```csv
VPO,2,Whittlesea,"Vegetation Protection Overlay - Schedule 2",20,,,Yes,Yes,Yes,"Limbs > 10cm diameter",Yes,Yes,Yes,Yes,Yes,"Fire prevention works within 10m of dwelling with CFA approval",Yes,Yes,"2:1 to 10:1 depending on quality",Yes,180.60,"28-60","$50,000-$100,000 + restoration costs",Council,Possible for native veg,"Schedule applies to native vegetation. Offset calculations use habitat hectares method. Council may refer to DELWP for significant native veg.",VERIFIED,2024-10-23,John Smith,https://planning-schemes.app.planning.vic.gov.au/Whittlesea/ordinance/42_02s02_whit.pdf,https://www.whittlesea.vic.gov.au/planning
```

## 🚨 CRITICAL NOTES

### DO:
✅ Copy EXACT wording from planning scheme
✅ Note if schedule says "native vegetation" vs "all trees"
✅ Record specific measurements (DBH, height, circumference)
✅ Note if requirements vary by zone (e.g., "residential vs industrial")
✅ Check for amendments (e.g., "VC289" - recent tree protection amendments)

### DON'T:
❌ Assume all schedules are the same
❌ Guess thresholds
❌ Mix up DBH (diameter) with circumference
❌ Forget to check for "Part B - Exemptions"
❌ Mark as VERIFIED without reading actual schedule document

## 📅 Key Victorian Amendments

### Amendment VC289 (Canopy Tree Protection):
- Added Clause 52.37 - Trees
- Applies to 31 metropolitan councils
- Protects canopy trees in gardens
- Check if this applies in your council!

### Where to find it:
https://www.planning.vic.gov.au/amendment/vc289

## 🗂️ Organizing Your Work

### Suggested Order:

1. **Start with VPO** (most important for trees)
   - Do Whittlesea VPO2 first (sample provided)
   - Then Melbourne, Yarra, Darebin
   - Work through all metro councils

2. **Then ESO** (environmental)
   - Focus on riparian/waterway schedules
   - Check "vegetation" sections

3. **Then SLO** (landscape)
   - Common in Dandenongs, Mornington Peninsula
   - Check tree height/retention clauses

4. **Then HO** (heritage)
   - All heritage sites
   - Usually "all trees" protected

5. **Skip schedules with no tree requirements**
   - Mark as "NO_TREE_REQUIREMENTS" in verification status
   - Add note: "No tree-specific requirements in this schedule"

## 🔗 Helpful Links

- **VicPlan Portal:** https://planning-schemes.app.planning.vic.gov.au/
- **Planning Victoria:** https://www.planning.vic.gov.au
- **Amendment VC289 (Trees):** https://www.planning.vic.gov.au/amendment/vc289
- **Native Vegetation Framework:** https://www.environment.vic.gov.au/native-vegetation

## ❓ If You're Stuck

### Can't find tree requirements?
- Search for keywords: "vegetation", "trees", "remove", "lop", "native"
- Check Part B (Exemptions) - often has tree details
- Some schedules have NO tree requirements (mark as such)

### Unclear measurement?
- DBH = Diameter at Breast Height (1.3m above ground)
- Circumference at 1m height is different!
- Circumference = π × diameter (roughly 3.14 times larger)
- If schedule says "10cm diameter", that's about 31cm circumference

### Need help understanding legal wording?
- Call the council planning department
- Ask: "Can you explain the tree requirements in [Overlay] Schedule [X]?"
- Document their answer in NOTES field

---

**This is detailed work, but it will create the most accurate overlay database in Victoria!** 🌳
