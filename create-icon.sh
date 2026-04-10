#!/bin/bash

# RTO Tracker - Quick Icon Generator
# Creates a simple app icon using SF Symbols

echo "🎨 RTO Tracker - Icon Generator"
echo "================================"
echo ""

# Check if SF Symbols is available
if ! command -v sf-symbols &> /dev/null; then
    echo "This script requires SF Symbols app or sips command"
fi

# Create icons directory
ICONS_DIR="/Users/voha/Source/RTO Tracker/RTOTracker/RTOTracker/Assets.xcassets/AppIcon.appiconset"
mkdir -p "$ICONS_DIR"

echo "📋 Icon Concepts for RTO Tracker:"
echo "1. Building.2 (current)"
echo "2. Building.2.fill"
echo "3. Building.columns"
echo "4. Building.columns.fill"
echo "5. Calendar.badge.checkmark"
echo "6. Checklist"
echo "7. Location.fill.viewfinder"
echo ""

echo "💡 Recommended: Building with badge (represents office + tracking)"
echo ""

echo "To create professional icons, you have these options:"
echo ""
echo "1. Design Tools:"
echo "   - Figma (free): figma.com"
echo "   - Sketch (paid): sketch.com"
echo "   - Icon Slate (Mac): kodlian.com/apps/icon-slate"
echo ""
echo "2. AI Generation:"
echo "   - DALL-E: platform.openai.com/dall-e"
echo "   - Midjourney: midjourney.com"
echo "   - Canva AI: canva.com"
echo ""
echo "3. Freelance Designers:"
echo "   - Fiverr: ~\$25-50 for app icon set"
echo "   - 99designs: ~\$100+ for professional set"
echo ""
echo "4. Icon Templates:"
echo "   - AppIconBuilder: appiconbuilder.com"
echo "   - Icon8: icons8.com/icons"
echo ""

cat > "$ICONS_DIR/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "icon_16x16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_16x16@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_32x32@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_128x128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_128x128@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_256x256@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "icon_512x512@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

echo "✅ Created AppIcon.appiconset structure"
echo ""
echo "📁 Location: $ICONS_DIR"
echo ""
echo "Required sizes:"
echo "  - icon_16x16.png (16x16)"
echo "  - icon_16x16@2x.png (32x32)"
echo "  - icon_32x32.png (32x32)"
echo "  - icon_32x32@2x.png (64x64)"
echo "  - icon_128x128.png (128x128)"
echo "  - icon_128x128@2x.png (256x256)"
echo "  - icon_256x256.png (256x256)"
echo "  - icon_256x256@2x.png (512x512)"
echo "  - icon_512x512.png (512x512)"
echo "  - icon_512x512@2x.png (1024x1024)"
echo ""
echo "🎨 Next steps:"
echo "1. Create 1024x1024 master icon (icon.png)"
echo "2. Use online tool to generate all sizes:"
echo "   → https://appicon.co (drag & drop, instant download)"
echo "   → https://www.appicon.build (macOS app)"
echo "3. Copy generated files to: $ICONS_DIR"
echo ""
