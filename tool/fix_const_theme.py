import re

files = [
    r"lib/screens/dashboard/dashboard_screen.dart",
    r"lib/screens/home/pieces_screen.dart",
    r"lib/screens/home/profile_screen.dart",
    r"lib/screens/home/settings_screen.dart",
    r"lib/widgets/pin_picker_dialog.dart",
    r"lib/widgets/load_error_view.dart",
]

for path in files:
    with open(path, encoding="utf-8") as f:
        s = f.read()
    s = s.replace("const Text(", "Text(")
    s = s.replace("style: const TextStyle(", "style: TextStyle(")
    s = s.replace("decoration: const InputDecoration(", "decoration: InputDecoration(")
    s = re.sub(
        r"const TextStyle\(color: context\.smartColors",
        "TextStyle(color: context.smartColors",
        s,
    )
    with open(path, "w", encoding="utf-8") as f:
        f.write(s)
    print("ok", path)
