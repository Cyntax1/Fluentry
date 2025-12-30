# Fluentry Website - Free Hosting Setup

## What You Have

3 simple HTML pages:
- `index.html` - Marketing homepage
- `support/index.html` - Support page
- `privacy/index.html` - Privacy policy

## FREE Hosting Options

### Option 1: GitHub Pages (Recommended - FREE)

**Steps:**
1. Create GitHub account (if you don't have one)
2. Create new repository called "fluentry-website"
3. Upload these files
4. Go to Settings → Pages
5. Enable GitHub Pages
6. Your site is live at: `yourusername.github.io/fluentry-website`

**Connect your domain:**
- In GitHub Pages settings, add your custom domain
- In your domain registrar, add CNAME record pointing to GitHub

### Option 2: Netlify (FREE)

1. Go to netlify.com
2. Drag and drop the `website` folder
3. Site is live instantly
4. Connect your custom domain in settings

### Option 3: Vercel (FREE)

1. Go to vercel.com
2. Import GitHub repo or drag folder
3. Deploy automatically
4. Connect custom domain

### Option 4: Cloudflare Pages (FREE)

1. Go to pages.cloudflare.com
2. Connect GitHub or upload files
3. Deploy
4. Use your domain (if it's on Cloudflare)

## File Structure

```
website/
├── index.html          (Marketing page)
├── support/
│   └── index.html      (Support page)
└── privacy/
    └── index.html      (Privacy page)
```

## URLs After Deployment

If your domain is `fluentry.com`:
- Marketing: `fluentry.com`
- Support: `fluentry.com/support`
- Privacy: `fluentry.com/privacy`

## Customization

### Change App Store Link
Search for `https://apps.apple.com/app/fluentry` and replace with your actual App Store URL

### Email Already Set
Support email is set to: `zenfasthelp@gmail.com`

### Change Colors
The purple gradient is: `#667eea` to `#764ba2`
Edit the CSS if you want different colors

## No Maintenance Required

These are static HTML files - no:
- Database needed
- Server maintenance
- Monthly hosting fees
- Complex setup

## Cost: $0

Everything is free except your domain name (which you already have).

## Quick Deploy (5 minutes)

1. Create GitHub account
2. New repo → Upload files
3. Settings → Pages → Enable
4. Done!

Your marketing and support URLs are ready for App Store Connect!
