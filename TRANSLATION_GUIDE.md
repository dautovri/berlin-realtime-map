# Translation Guide

This document outlines how to manage translations and multi-language support for this app.

## Current Supported Languages

| Language | Code | App Store Metadata | App UI | Screenshots |
|----------|------|---|---|---|
| English | en-US | ✅ | ✅ | ⏳ |
| German | de-DE | ✅ | ✅ | ⏳ |

## Adding New Translations

### Step 1: Add Language to Xcode Project

1. Open the `.xcodeproj` file in Xcode
2. Select the project
3. Go to **Project Settings** → **Info** tab
4. Under **Localizations**, click the **+** button
5. Select the new language (e.g., French, Spanish)

### Step 2: Create Localizable.strings Files

Create language-specific `.strings` files:

```
BerlinTransportMap/
├── en.lproj/
│   └── Localizable.strings
├── de.lproj/
│   └── Localizable.strings
└── fr.lproj/          # New
    └── Localizable.strings
```

### Step 3: Add App Store Metadata

Create metadata directories:

```
fastlane/metadata/
├── en-US/             # Already exists
├── de-DE/             # Already exists
└── fr-FR/             # Create new
    ├── name.txt
    ├── subtitle.txt
    ├── description.txt
    ├── keywords.txt
    ├── promotional_text.txt
    ├── release_notes.txt
    ├── privacy_url.txt
    ├── marketing_url.txt
    └── support_url.txt
```

### Step 4: Regional Considerations

**For Berlin/Berlin-specific markets:**

- **German (de-DE)**: Primary market; emphasize BVG, U-Bahn, S-Bahn, local transport
- **Dutch (nl-NL)**: Netherlands expansion; mention connection to Berlin/VBB
- **French (fr-FR)**: EU market; generic Berlin reference

### Step 5: Generate Localized Screenshots

```bash
# Capture screenshots for all locales
fastlane capture_screenshots_multi_language

# Or manually for each locale
fastlane capture_screenshots locale:en-US
fastlane capture_screenshots locale:de-DE
```

### Step 6: Upload to App Store

```bash
# Upload metadata for all locales
fastlane upload_metadata_all_locales

# Or individual upload
fastlane upload_metadata locale:de-DE
```

## Translation Workflow

### Using POEditor (Recommended for Multi-Language)

1. **Create Project**: Sign up at [POEditor.com](https://poeditor.com)
2. **Add Reference Language**: en-US
3. **Export .strings**: Export from Xcode to `.strings` format
4. **Upload to POEditor**: Import the source `.strings` file
5. **Add Target Languages**: de-DE, fr-FR, nl-NL
6. **Invite Translators**: Add native speakers
7. **Export Translations**: Download translated `.strings` files
8. **Import to Xcode**: Replace the localized `.strings` files
9. **Test**: Verify all strings in each language

### Manual Translation Process

1. **Identify All Strings**: Use `NSLocalizedString()` for all UI text
2. **Extract to Spreadsheet**: Copy keys, English values, and context
3. **Translate**: Have native speakers translate
4. **Create .strings Files**: Create locale-specific `.strings` files
5. **Test**: Run app in each locale
6. **Review**: Verify context, grammar, and layout
7. **Iterate**: Fix any translation issues

## Translation Quality Checklist

- [ ] All strings have proper context comments
- [ ] No hardcoded strings in UI code
- [ ] Correct grammar, punctuation, and capitalization
- [ ] Special characters (ä, ö, ü, etc.) display correctly
- [ ] Longer translations don't break layout
- [ ] All placeholders (%@, %d) preserved
- [ ] Tested in light and dark mode
- [ ] Regional terms used correctly (e.g., "BVG" for Berlin)
- [ ] Reviewed by native speaker
- [ ] App Store metadata professionally proofread

## String File Format

Example `Localizable.strings` (UTF-8 encoded):

```swift
/* Navigation & Main View */
"Berlin Transport Map" = "Berlin Transport Map";
"Live vehicle radar and nearby stops" = "Live vehicle radar and nearby stops";
"No Departures" = "No Departures";
"No upcoming departures at this stop" = "No upcoming departures at this stop";

/* Transit Modes */
"S-Bahn" = "S-Bahn";
"U-Bahn" = "U-Bahn";
"Tram" = "Tram";
"Bus" = "Bus";

/* Status */
"Cancelled" = "Cancelled";

/* Actions */
"Show Route" = "Show Route";
"Done" = "Done";
```

German equivalent:

```swift
/* Navigation & Main View */
"Berlin Transport Map" = "Berlin Nahverkehr Live";
"Live vehicle radar and nearby stops" = "Live-Fahrzeugkarte und nahegelegene Haltestellen";
"No Departures" = "Keine Abfahrten";
"No upcoming departures at this stop" = "Keine bevorstehenden Abfahrten an dieser Haltestelle";

/* Transit Modes */
"S-Bahn" = "S-Bahn";
"U-Bahn" = "U-Bahn";
"Tram" = "Straßenbahn";
"Bus" = "Bus";

/* Status */
"Cancelled" = "Ausfall";

/* Actions */
"Show Route" = "Route anzeigen";
"Done" = "Fertig";
```

## App Store Metadata Translation Tips

### Keywords (Regional)

**German (de-DE):**
- Include: BVG, ÖPNV, U-Bahn, S-Bahn, Nahverkehr, Berlin Verkehr, Echtzeit
- Example: `berlin,nahverkehr,bvg,oepnv,u-bahn,s-bahn,echtzeit`

**French (fr-FR):**
- Include: transport, Berlin, carte, en temps réel
- Example: `berlin,transport,carte,en temps reel,vbb`

### Description

- **German**: Emphasize regional dominance (BVG, Berlin market) - 160-180 chars
- **French**: More generic (EU market) - mention "Berlin" but position as international - 160-180 chars

### Promotional Text

- Market-specific features
- 170 characters max
- Example DE: "Live-Fahrzeugpositionierung für die BVG und VBB. Erkunden Sie Berlin in Echtzeit."
- Example FR: "Suivez les véhicules de transport en temps réel à Berlin."

## Git Workflow for Translations

```bash
# Create feature branch
git checkout -b feature/add-french-translations

# Add new language .strings files
git add "**/fr.lproj/Localizable.strings"

# Add App Store metadata
git add "fastlane/metadata/fr-FR/"

# Commit with clear message
git commit -m "Add French (fr-FR) translations for Berlin Transport Map

- Added French UI translations (fr.lproj/Localizable.strings)
- Added French App Store metadata (fastlane/metadata/fr-FR/)
- Translated 25 UI strings + App Store description
- Verified special characters (é, ç) display correctly
- Reviewed by native French speaker"

# Push and create PR
git push origin feature/add-french-translations
```

## Maintenance & Updates

- [ ] Review translations quarterly for consistency
- [ ] Update all languages when UI strings change
- [ ] Monitor user reviews for translation feedback
- [ ] Keep language files in sync
- [ ] Archive deprecated strings with comments

## Escalation & Contact

- **Translation Issues**: Create GitHub issue with tag `translation`
- **Regional Feedback**: Monitor App Store reviews per locale
- **Professional Translator**: [Contact info]
- **POEditor Admin**: [Admin login/contact]

## Localization Per Region (Recommended Rollout)

### Phase 1 (Current)
- ✅ English (en-US)
- ✅ German (de-DE) - Primary market

### Phase 2 (Next Quarter)
- French (fr-FR) - EU expansion
- Dutch (nl-NL) - Regional expansion

### Phase 3 (Future)
- Spanish (es-ES)
- Italian (it-IT)
- Swedish (sv-SE)

---

**Last Updated**: 2026-01-22  
**Version**: 1.0  
**Maintained By**: [Your Name]  
**Berlin Market Focus**: Yes - Regional strategy prioritizes DACH region
