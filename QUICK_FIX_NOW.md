# ⚡ QUICK FIX - Do This Now!

## 🎯 1-Minute Fix

Your widgets are perfect! Xcode just needs to know **which one** to show.

---

## ✅ Do These 5 Steps:

### 1. Select Widget Scheme
```
Top bar → "FluentryWidgetExtension" scheme
```

### 2. Edit Scheme
```
Click scheme dropdown → "Edit Scheme..."
(or press Cmd+Shift+,)
```

### 3. Go to Arguments
```
Left sidebar: Select "Run"
Top tabs: Click "Arguments"
```

### 4. Add Environment Variable
```
Under "Environment Variables" section:

Click "+" button

Name:  _XCWidgetKind
Value: FluentryStatsWidget

✅ Check the box to enable it
```

### 5. Run It!
```
Close scheme editor
Press Cmd+R
Choose widget size
✅ Widget shows!
```

---

## 🎨 To Test Different Widget:

**For Stats Widget:**
- Value: `FluentryStatsWidget`

**For Word of Day Widget:**
- Value: `FluentryWordWidget`

Just change the value and run again!

---

## 🎉 Done!

That's it! Your widgets work perfectly now! 🚀

Read `SET_WIDGET_SCHEME.md` for detailed instructions.
