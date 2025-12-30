# 🔍 Find Widget Scheme - Clear Instructions

## 📍 Where to Look

The scheme selector is **NOT in the left sidebar** - it's at the **TOP of Xcode**!

---

## ✅ Step-by-Step

### 1. Look at the TOP BAR (Next to Play/Stop buttons)

You'll see something like:
```
┌─────────────────────────────────┐
│ Fluentry > iPhone 15 Pro        │  ← This is the scheme selector
└─────────────────────────────────┘
```

### 2. Click on "Fluentry" Text

A dropdown menu appears with all schemes:
- Fluentry
- FluentryTests  
- FluentryUITests
- **FluentryWidget** ← This is your widget!
  (might also be called "FluentryWidgetExtension")

### 3. Select the Widget Scheme

Click on:
- `FluentryWidget`
- OR `FluentryWidgetExtension`

---

## 🎯 Visual Guide

```
TOP BAR OF XCODE:
┌────────────────────────────────────────────────┐
│  ▶ ■  [Fluentry ▼] [iPhone 15 Pro ▼]         │
│         ^                                      │
│         └─ CLICK HERE                         │
└────────────────────────────────────────────────┘

DROPDOWN SHOWS:
┌──────────────────────────┐
│ Fluentry                 │
│ FluentryTests            │
│ FluentryUITests          │
│ FluentryWidget          │ ← SELECT THIS!
└──────────────────────────┘
```

---

## 🔧 After Selecting Widget Scheme

### Then Edit It:

1. **Click scheme name again**
2. **Select "Edit Scheme..."** from dropdown
3. OR press **Cmd + Shift + ,** (comma)

### Then Add Environment Variable:

1. **Left sidebar:** Click "Run"
2. **Top tabs:** Click "Arguments"
3. **Environment Variables section:** Click "+"
4. **Add:**
   - Name: `_XCWidgetKind`
   - Value: `FluentryStatsWidget`
5. **Check the box** to enable
6. **Close**

---

## 💡 Can't Find Widget Scheme?

### Check All Schemes:

**Product** → **Scheme** → **Manage Schemes...**

Look for:
- FluentryWidget
- FluentryWidgetExtension
- Any scheme with "Widget" in the name

If you see it, make sure it's **checked** (enabled).

---

## 🎯 Quick Summary

1. **Look at TOP BAR** (not left sidebar)
2. **Click scheme dropdown** (next to play button)
3. **Select FluentryWidget** or FluentryWidgetExtension
4. **Edit scheme** (Cmd+Shift+,)
5. **Add environment variable**
6. **Run!**

---

## ✅ That's It!

The widget scheme is at the **top** of Xcode, not the left! 🎉
