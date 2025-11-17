#!/bin/bash
# Push to GitHub using Personal Access Token

echo "=========================================="
echo "  Push LocalTrade to GitHub"
echo "=========================================="
echo ""
echo "You need a Personal Access Token from GitHub"
echo ""
echo "Steps:"
echo "1. Go to: https://github.com/settings/tokens"
echo "2. Click 'Generate new token (classic)'"
echo "3. Name it: 'LocalTrade Push'"
echo "4. Select scope: 'repo' (full control)"
echo "5. Generate and COPY the token"
echo ""
echo "When prompted:"
echo "  Username: NSABAbUTUULO001"
echo "  Password: [paste your token here]"
echo ""
echo "Press Enter when ready, or Ctrl+C to cancel..."
read

git push -u origin main
