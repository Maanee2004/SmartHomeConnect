import re

path = r"lib/screens/dashboard/dashboard_screen.dart"
with open(path, encoding="utf-8") as f:
    s = f.read()

if "smart_home_colors.dart" not in s:
    s = s.replace(
        "import 'package:smart_home/theme/room_icons.dart';",
        "import 'package:smart_home/theme/room_icons.dart';\n"
        "import 'package:smart_home/theme/smart_home_colors.dart';",
    )

s = re.sub(r"\n\s*backgroundColor: (bgColor|cardColor),", "", s)
s = s.replace("color: textPrimary", "color: c.textPrimary")
s = s.replace("color: textSecondary", "color: c.textSecondary")
s = s.replace("dropdownColor: cardColor", "dropdownColor: c.card")
s = s.replace("const TextStyle(color: c.textPrimary)", "TextStyle(color: c.textPrimary)")
s = s.replace("style: const TextStyle(color: c.textPrimary)", "style: TextStyle(color: c.textPrimary)")

s = s.replace(
    "Widget build(BuildContext context) {\n    final firebaseReady",
    "Widget build(BuildContext context) {\n    final c = context.smartColors;\n    final firebaseReady",
)

replacements = [
    (
        "builder: (ctx) {\n        return SafeArea",
        "builder: (ctx) {\n        final c = ctx.smartColors;\n        return SafeArea",
    ),
    (
        "builder: (ctx) => SafeArea",
        "builder: (ctx) {\n        final c = ctx.smartColors;\n        return SafeArea",
    ),
    (
        "builder: (ctx, setSt) {\n            return AlertDialog",
        "builder: (ctx, setSt) {\n            final c = ctx.smartColors;\n            return AlertDialog",
    ),
    (
        "builder: (ctx) => AlertDialog",
        "builder: (ctx) {\n        final c = ctx.smartColors;\n        return AlertDialog",
    ),
    (
        "builder: (context, snap) {\n        final raw = snap",
        "builder: (context, snap) {\n        final c = context.smartColors;\n        final raw = snap",
    ),
    (
        "builder: (context, snap) {\n            final rooms = snap.data",
        "builder: (context, snap) {\n            final c = context.smartColors;\n            final rooms = snap.data",
    ),
    (
        "builder: (context, snap) {\n              final rooms = snap.data",
        "builder: (context, snap) {\n              final c = context.smartColors;\n              final rooms = snap.data",
    ),
    (
        "builder: (context, roomSnap) {\n                        if (roomSnap.hasError",
        "builder: (context, roomSnap) {\n                        final c = context.smartColors;\n                        if (roomSnap.hasError",
    ),
    (
        "builder: (context, devSnap) {\n                            if (devSnap.hasError",
        "builder: (context, devSnap) {\n                            final c = context.smartColors;\n                            if (devSnap.hasError",
    ),
]
for old, new in replacements:
    s = s.replace(old, new)

with open(path, "w", encoding="utf-8") as f:
    f.write(s)
print("dashboard updated")
