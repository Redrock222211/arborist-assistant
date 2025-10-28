# Tree Form Enhancement Recommendations

## Current Field Analysis
Your tree form currently has **40+ fields** organized into these sections:
1. **Photos** - Image capture and management
2. **Voice Notes** - Audio recording
3. **GPS Location** - Coordinates and protection zones
4. **Basic Tree Information** - Species, DSH, Height, Condition, etc.
5. **Tree Assessment & Health** - Age, retention value, diseases, pests
6. **VTA & Risk Assessment** - Failure likelihood, impact, risk ratings
7. **Additional Information** - Location description, habitat value, etc.

---

## Recommended Additional Fields by Category

### 📍 **1. SITE CONTEXT & LOCATION** (Export Group: "Site Context")
**New Fields to Add:**
- **Land Use Zone** (Dropdown: Residential, Commercial, Industrial, Parkland, Conservation, Rural)
- **Proximity to Buildings** (Number in meters)
- **Proximity to Roads** (Number in meters)
- **Proximity to Power Lines** (Yes/No + Distance in meters)
- **Site Slope** (Dropdown: Flat, Gentle, Moderate, Steep)
- **Aspect/Orientation** (Dropdown: North, South, East, West, NE, NW, SE, SW)
- **Soil Type** (Dropdown: Clay, Loam, Sand, Rocky, Mixed, Unknown)
- **Drainage Condition** (Dropdown: Excellent, Good, Fair, Poor, Waterlogged)
- **Soil Compaction** (Dropdown: None, Light, Moderate, Severe)

**Why:** Better environmental context for tree health assessment and risk evaluation.

---

### 🌳 **2. TREE STRUCTURE & FORM** (Export Group: "Tree Structure")
**New Fields to Add:**
- **Crown Form** (Dropdown: Columnar, Pyramidal, Rounded, Spreading, Weeping, Irregular)
- **Crown Density** (Dropdown: Dense, Moderate, Sparse, Very Sparse)
- **Crown Dieback %** (Number 0-100)
- **Branch Structure** (Dropdown: Excellent, Good, Fair, Poor, Critical)
- **Trunk Form** (Dropdown: Single, Multi-stem, Co-dominant, Forked)
- **Trunk Lean** (Dropdown: None, Slight <15°, Moderate 15-30°, Severe >30°)
- **Lean Direction** (Compass: N, S, E, W, NE, NW, SE, SW)
- **Root Plate Condition** (Dropdown: Stable, Slight Lift, Moderate Lift, Severe Lift, Exposed)
- **Buttress Roots Visible** (Yes/No)
- **Epicormic Growth** (Dropdown: None, Light, Moderate, Heavy)

**Why:** Critical for structural assessment and stability evaluation.

---

### 🐛 **3. DETAILED DEFECTS & DAMAGE** (Export Group: "Defects")
**New Fields to Add:**
- **Cavity Present** (Yes/No)
- **Cavity Size** (Dropdown: Small <10cm, Medium 10-30cm, Large >30cm)
- **Cavity Location** (Dropdown: Base, Lower Trunk, Mid Trunk, Upper Trunk, Branch)
- **Decay Extent** (Dropdown: None, Minor <25%, Moderate 25-50%, Extensive >50%)
- **Fungal Fruiting Bodies** (Yes/No + Text description)
- **Bark Damage %** (Number 0-100)
- **Bark Damage Type** (Multi-select: Mechanical, Fire, Sunscald, Disease, Animal, Vandalism)
- **Dead Wood %** (Number 0-100)
- **Included Bark** (Yes/No + Location)
- **Cracks/Splits** (Yes/No + Location + Severity)
- **Girdling Roots** (Yes/No + Severity)

**Why:** Essential for VTA (Visual Tree Assessment) and detailed defect documentation.

---

### 🔧 **4. MANAGEMENT & WORKS** (Export Group: "Management")
**New Fields to Add:**
- **Previous Works Date** (Date picker)
- **Previous Works Type** (Multi-select: Prune, Reduce, Remove Deadwood, Cable/Brace, Root Work, Other)
- **Pruning Type Recommended** (Multi-select: Deadwood, Crown Thin, Crown Lift, Crown Reduce, Formative, Structural, Clearance)
- **Pruning Priority** (Dropdown: Urgent, High, Medium, Low, Monitor)
- **Pruning Timeframe** (Dropdown: Immediate, 1-3 months, 3-6 months, 6-12 months, 1-2 years)
- **Estimated Cost Range** (Dropdown: <$500, $500-1000, $1000-2500, $2500-5000, >$5000)
- **Access Requirements** (Multi-select: Crane, EWP, Climber, Road Closure, Traffic Management)
- **Permit Status** (Dropdown: Not Required, Required - Not Applied, Applied - Pending, Approved, Denied)
- **Permit Number** (Text)
- **Permit Expiry Date** (Date picker)

**Why:** Better project planning, costing, and permit tracking.

---

### 🌱 **5. ECOLOGICAL & AMENITY VALUE** (Export Group: "Ecology")
**New Fields to Add:**
- **Wildlife Habitat Value** (Dropdown: None, Low, Moderate, High, Critical)
- **Hollow Bearing Tree** (Yes/No)
- **Nesting Sites Observed** (Yes/No + Species if known)
- **Significant Tree** (Yes/No - Heritage, Cultural, Landscape)
- **Amenity Value** (Dropdown: Low, Moderate, High, Very High)
- **Shade Provision** (Dropdown: None, Minimal, Moderate, Significant)
- **Screening Value** (Dropdown: None, Low, Moderate, High)
- **Cultural Significance** (Text field)
- **Indigenous Significance** (Yes/No + Notes)

**Why:** Important for environmental assessments and planning overlays.

---

### 📊 **6. QUANTIFIED TREE RISK ASSESSMENT (QTRA)** (Export Group: "QTRA")
**New Fields to Add:**
- **Target Type** (Dropdown: Pedestrian, Vehicle, Building, Service, Recreation Area, Other)
- **Target Value** (Dropdown: Low, Medium, High, Very High)
- **Occupancy Rate** (Dropdown: Rare, Occasional, Frequent, Constant)
- **Impact Potential** (Dropdown: Whole Tree, Part of Tree, Branch, Limb)
- **Probability of Failure** (Number 1 in X format, e.g., 1 in 10,000)
- **Probability of Impact** (Number 0-1 as decimal)
- **Risk of Harm** (Auto-calculated from above)
- **QTRA Risk Rating** (Auto-calculated: Acceptable, Tolerable, Unacceptable)
- **Risk Mitigation Required** (Yes/No)
- **Risk Mitigation Actions** (Text field)

**Why:** Professional QTRA methodology for quantified risk assessment.

---

### 🔬 **7. ADVANCED DIAGNOSTICS** (Export Group: "Diagnostics")
**New Fields to Add:**
- **Resistograph Test Done** (Yes/No + Date)
- **Resistograph Results** (Text + File attachment)
- **Sonic Tomography Done** (Yes/No + Date)
- **Sonic Tomography Results** (Text + File attachment)
- **Pulling Test Done** (Yes/No + Date)
- **Pulling Test Results** (Text + File attachment)
- **Root Collar Excavation** (Yes/No + Findings)
- **Soil Testing Done** (Yes/No + Results)
- **Pathology Report** (File attachment)

**Why:** For advanced assessments and expert reports.

---

### 📅 **8. MONITORING & SCHEDULING** (Export Group: "Monitoring")
**New Fields to Add:**
- **Next Inspection Date** (Date picker)
- **Inspection Frequency** (Dropdown: 3 months, 6 months, 12 months, 18 months, 2 years, 3 years)
- **Monitoring Required** (Yes/No)
- **Monitoring Focus** (Multi-select: Stability, Health, Growth, Defects, Works Compliance)
- **Alert/Flag** (Dropdown: None, Watch, Caution, Urgent, Critical)
- **Follow-up Actions** (Text field)
- **Compliance Check Required** (Yes/No)
- **Compliance Due Date** (Date picker)

**Why:** Proactive tree management and scheduling.

---

### 📝 **9. REGULATORY & COMPLIANCE** (Export Group: "Compliance")
**New Fields to Add:**
- **Planning Overlay** (Auto-filled from VICMAP if available)
- **Heritage Overlay** (Yes/No)
- **Significant Landscape Overlay** (Yes/No)
- **Vegetation Protection Overlay** (Yes/No)
- **Local Law Protected** (Yes/No + Reference)
- **State Significant** (Yes/No)
- **Bushfire Management Overlay** (Yes/No)
- **AS4970 Compliant** (Yes/No - Australian Standard)
- **Insurance Notification Required** (Yes/No)
- **Neighbor Notification Required** (Yes/No)

**Why:** Legal compliance and planning requirements.

---

### 💰 **10. FINANCIAL & INSURANCE** (Export Group: "Financial")
**New Fields to Add:**
- **Tree Valuation Method** (Dropdown: CTLA, Helliwell, Burnley, Other)
- **Estimated Tree Value** (Currency)
- **Valuation Date** (Date picker)
- **Insurance Claim** (Yes/No)
- **Insurance Claim Number** (Text)
- **Liability Assessment** (Dropdown: Low, Moderate, High, Critical)
- **Asset Number** (Text - for council/corporate trees)
- **Maintenance Budget Code** (Text)

**Why:** Asset management and insurance purposes.

---

## Implementation: Export Group Checkboxes

### Recommended UI Enhancement:

```dart
// Add to TreeEntry model
Map<String, bool> exportGroups = {
  'site_context': true,
  'tree_structure': true,
  'defects': true,
  'management': true,
  'ecology': true,
  'qtra': true,
  'diagnostics': false,  // Optional advanced
  'monitoring': true,
  'compliance': true,
  'financial': false,    // Optional
};
```

### Export Dialog UI:
```
┌─────────────────────────────────────┐
│  Select Data Groups to Export       │
├─────────────────────────────────────┤
│  ☑ Site Context & Location          │
│  ☑ Tree Structure & Form            │
│  ☑ Defects & Damage                 │
│  ☑ Management & Works                │
│  ☑ Ecology & Amenity                │
│  ☑ QTRA Risk Assessment             │
│  ☐ Advanced Diagnostics             │
│  ☑ Monitoring & Scheduling          │
│  ☑ Regulatory & Compliance          │
│  ☐ Financial & Insurance            │
├─────────────────────────────────────┤
│  [Select All] [Deselect All]        │
│                                      │
│  [Cancel]  [Export Selected Groups] │
└─────────────────────────────────────┘
```

---

## Priority Implementation Order

### Phase 1 (High Priority - Core Professional Fields):
1. **Tree Structure & Form** - Essential for assessment
2. **Detailed Defects & Damage** - Critical for VTA
3. **Management & Works** - Practical job planning
4. **Monitoring & Scheduling** - Proactive management

### Phase 2 (Medium Priority - Enhanced Professional):
5. **Site Context & Location** - Environmental factors
6. **QTRA Risk Assessment** - Quantified risk methodology
7. **Regulatory & Compliance** - Legal requirements

### Phase 3 (Optional - Advanced/Specialized):
8. **Advanced Diagnostics** - For specialist reports
9. **Ecological & Amenity Value** - Environmental assessments
10. **Financial & Insurance** - Asset management

---

## Benefits of This Approach

✅ **Comprehensive Data** - Covers all aspects of professional arboriculture  
✅ **Flexible Exports** - Choose what data to include per client/purpose  
✅ **Regulatory Compliance** - Meets Australian standards (AS4970, QTRA)  
✅ **Professional Reports** - Generate ISA, VTA, QTRA compliant reports  
✅ **Efficient Workflow** - Hide advanced fields until needed  
✅ **Data Privacy** - Exclude sensitive financial/diagnostic data when needed  
✅ **Client-Specific** - Export only relevant data for each stakeholder  

---

## Next Steps

1. **Review** this document and select which field groups to implement
2. **Prioritize** based on your immediate client needs
3. **Design** collapsible card sections in the form (like current structure)
4. **Add** export group checkboxes to the export dialog
5. **Update** PDF/CSV export services to filter by selected groups
6. **Test** with real-world tree assessments

Would you like me to implement any of these sections into the tree form?
