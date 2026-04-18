#!/bin/bash

# Replace bridge widget usages with PremiumExtension calls

cd /Users/namanshergill/Desktop/dev/diohub

# Replace LensButton with premium extension call
# Pattern: LensButton(lensContext: ...) => ref.read(premiumExtensionProvider).buildLensButton(context, ref) ?? SizedBox.shrink()

find lib -name "*.dart" -type f -exec sed -i '' \
  -e 's/LensButton([^)]*)/ref.read(premiumExtensionProvider).buildLensButton(context, ref) ?? const SizedBox.shrink()/g' \
  {} \;

# Replace AiSummaryChip with premium extension call
find lib -name "*.dart" -type f -exec sed -i '' \
  -e 's/AiSummaryChip(/ref.read(premiumExtensionProvider).buildAiSummaryChip(context, ref, /g' \
  {} \;

# Replace AiComposeActionsPopup with premium extension call  
find lib -name "*.dart" -type f -exec sed -i '' \
  -e 's/AiComposeActionsPopup(/ref.read(premiumExtensionProvider).buildComposeAiActions(context, ref, /g' \
  {} \;

# Remove LensContext variable declarations and usages
find lib -name "*.dart" -type f -exec sed -i '' \
  -e '/final.*LensContext.*=.*LensContext\./d' \
  -e '/LensContext\?.*lensContext.*=/d' \
  {} \;

echo "Widget usages replaced with PremiumExtension calls"
