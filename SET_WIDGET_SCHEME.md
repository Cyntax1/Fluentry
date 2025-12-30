# 🔧 Set Widget Scheme - Quick Fix

## 🎯 The Problem

Xcode doesn't know which widget to show because you now have **2 widget types**:
- `FluentryStatsWidget` (Learning Stats)
- `FluentryWordWidget` (Word of the Day)

## ✅ The Solution (1 Minute)

### Option 1: Set Default Widget in Scheme

**In Xcode:**

1. **Select "FluentryWidgetExtension" scheme** (top bar)

2. **Click scheme dropdown** → **"Edit Scheme..."**
   - Or press: **Cmd + Shift + ,** (comma)

3. **Select "Run"** in left sidebar

4. **Go to "Arguments" tab**

5. **Under "Environment Variables"** section:
   - Click **"+"** button
   - Name: `_XCWidgetKind`
   - Value: `FluentryStatsWidget`
     (or `FluentryWordWidget` if you prefer)

6. **Check the box** next to the variable to enable it

7. **Close** the scheme editor

8. **Run widget** (Cmd + R)

9. **✅ Widget shows!**

---

### Option 2: Create Two Schemes (Recommended)

Create separate schemes for each widget type:

#### For Stats Widget:

1. **Product** → **Scheme** → **Manage Schemes...**

2. **Select "FluentryWidgetExtension"**

3. **Click gear icon** → **Duplicate**

4. **Rename to**: `FluentryWidget - Stats`

5. **Close** scheme manager

6. **Edit scheme** (Cmd+Shift+,)
   - Arguments → Environment Variables
   - Add: `_XCWidgetKind` = `FluentryStatsWidget`

7. **Close**

#### For Word Widget:

1. **Product** → **Scheme** → **Manage Schemes...**

2. **Select "FluentryWidgetExtension"**

3. **Click gear icon** → **Duplicate**

4. **Rename to**: `FluentryWidget - Word`

5. **Close** scheme manager

6. **Edit scheme** (Cmd+Shift+,)
   - Arguments → Environment Variables
   - Add: `_XCWidgetKind` = `FluentryWordWidget`

7. **Close**

---

## 🚀 Usage

### After Setup:

**To test Stats Widget:**
1. Select `FluentryWidget - Stats` scheme
2. Run (Cmd+R)
3. ✅ Stats widget appears!

**To test Word Widget:**
1. Select `FluentryWidget - Word` scheme
2. Run (Cmd+R)
3. ✅ Word widget appears!

---

## 📝 Quick Reference

### Environment Variable Format:
```
Name:  _XCWidgetKind
Value: FluentryStatsWidget
       (or FluentryWordWidget)
```

### Widget Kind Values:
- `FluentryStatsWidget` - Shows stats and streak
- `FluentryWordWidget` - Shows word of the day

---

## 💡 Pro Tip

After setting this up, you can:
1. **Switch schemes** to test different widgets
2. **Choose size** when widget launches
3. **All sizes work** (Small, Medium, Large)

---

## ✅ That's It!

Just add the environment variable and your widgets will work perfectly! 🎉

No more errors, smooth testing, beautiful widgets! ✨
