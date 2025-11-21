#!/bin/bash

# Arborist Assistant Test Distribution Script

echo "🌳 Arborist Assistant - Test Build Distribution"
echo "================================================"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Not in Flutter project directory"
    exit 1
fi

echo -e "${BLUE}Building test APK...${NC}"

# Build the APK
flutter build apk --release

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Build successful!${NC}"
    
    APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
    
    if [ -f "$APK_PATH" ]; then
        # Get file size
        SIZE=$(du -h "$APK_PATH" | cut -f1)
        
        echo ""
        echo -e "${GREEN}📱 APK Details:${NC}"
        echo "   Path: $APK_PATH"
        echo "   Size: $SIZE"
        echo ""
        
        # Create distribution folder
        DIST_DIR="distribution"
        mkdir -p "$DIST_DIR"
        
        # Copy APK with version name
        VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //')
        DIST_NAME="ArboristAssistant_v${VERSION}_test.apk"
        cp "$APK_PATH" "$DIST_DIR/$DIST_NAME"
        
        echo -e "${GREEN}📦 Distribution package created:${NC}"
        echo "   $DIST_DIR/$DIST_NAME"
        echo ""
        
        # Create installation instructions
        cat > "$DIST_DIR/INSTALL_INSTRUCTIONS.txt" << EOF
ARBORIST ASSISTANT - TEST VERSION
==================================

Version: $VERSION
Build Date: $(date)

ANDROID INSTALLATION:
--------------------
1. Transfer the APK file to your Android device
2. On your device, go to Settings > Security
3. Enable "Install from Unknown Sources"
4. Open the APK file using a file manager
5. Tap "Install"
6. Once installed, tap "Open" to launch the app

TROUBLESHOOTING:
---------------
- If you see "App not installed", uninstall any previous version first
- For Android 8+, you may need to enable "Install unknown apps" for your browser/file manager
- Minimum Android version: 5.0 (API 21)

FEEDBACK:
--------
Please report any issues or feedback to the development team.

Thank you for testing!
EOF
        
        echo -e "${YELLOW}📋 Installation instructions created${NC}"
        echo ""
        echo -e "${GREEN}✨ Ready for distribution!${NC}"
        echo ""
        echo "Distribution options:"
        echo "1. Upload to Google Drive/Dropbox and share link"
        echo "2. Email the APK directly (if under 25MB)"
        echo "3. Use Firebase App Distribution"
        echo "4. Upload to a file sharing service"
        echo ""
        echo -e "${BLUE}Files ready in: $DIST_DIR/${NC}"
        
        # Open the distribution folder
        if [[ "$OSTYPE" == "darwin"* ]]; then
            open "$DIST_DIR"
        fi
        
    else
        echo "❌ APK file not found at expected location"
        exit 1
    fi
else
    echo "❌ Build failed"
    exit 1
fi
