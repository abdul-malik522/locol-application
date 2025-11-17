# Fix GitHub Authentication

## Problem

You're authenticated as `abdul-malik5` but trying to push to `NSABAbUTUULO001/CANDY-MACHINE.git`.

## Solutions

### Option 1: Use Personal Access Token (Recommended)

1. **Create a Personal Access Token:**
   - Go to: https://github.com/settings/tokens
   - Click "Generate new token (classic)"
   - Name: "LocalTrade Push"
   - Select scope: `repo` (full control)
   - Generate and **copy the token**

2. **Push with token:**
   ```bash
   cd /home/bu2lo/LOCOL
   git push -u origin main
   ```
   When prompted:
   - **Username**: `NSABAbUTUULO001`
   - **Password**: `[paste your personal access token]`

### Option 2: Clear Credentials and Re-authenticate

```bash
# Clear cached credentials
git credential-cache exit 2>&1
git config --global --unset credential.helper

# Or remove from credential store
git credential reject <<EOF
protocol=https
host=github.com
EOF

# Then push (will prompt for credentials)
git push -u origin main
```

### Option 3: Use SSH (If you have access to NSABAbUTUULO001 account)

1. **Generate SSH key for NSABAbUTUULO001 account:**
   ```bash
   ssh-keygen -t ed25519 -C "NSABAbUTUULO001@github.com" -f ~/.ssh/id_ed25519_nsaba
   ```

2. **Add SSH key to NSABAbUTUULO001 GitHub account:**
   - Copy: `cat ~/.ssh/id_ed25519_nsaba.pub`
   - Add at: https://github.com/settings/keys (while logged in as NSABAbUTUULO001)

3. **Configure SSH and push:**
   ```bash
   # Add to ~/.ssh/config
   cat >> ~/.ssh/config <<EOF
   Host github-nsaba
       HostName github.com
       User git
       IdentityFile ~/.ssh/id_ed25519_nsaba
   EOF

   # Change remote URL
   git remote set-url origin git@github-nsaba:NSABAbUTUULO001/CANDY-MACHINE.git
   
   # Push
   git push -u origin main
   ```

### Option 4: Fork Repository (If you don't have access)

If you don't have access to NSABAbUTUULO001's repository:

1. **Fork the repository** to your account (abdul-malik5)
2. **Change remote:**
   ```bash
   git remote set-url origin https://github.com/abdul-malik5/CANDY-MACHINE.git
   git push -u origin main
   ```

## Quick Fix (Try This First)

```bash
cd /home/bu2lo/LOCOL

# Clear credentials
git config --global --unset credential.helper
git credential-cache exit 2>&1 || true

# Push (will prompt for credentials)
git push -u origin main
# Enter: NSABAbUTUULO001 as username
# Enter: [your personal access token] as password
```

## Important Notes

- **Personal Access Token** is the easiest method
- Make sure you're logged into GitHub as **NSABAbUTUULO001** when creating the token
- The token acts as your password
- Store the token securely (you won't see it again)

