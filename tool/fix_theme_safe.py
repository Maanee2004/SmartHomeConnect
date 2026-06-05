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
    try:
        with open(path, encoding="utf-8") as f:
            s = f.read()
    except FileNotFoundError:
        continue

    if "smart_home_colors.dart" not in s:
        s = s.replace(
            "import 'package:smart_home/constants.dart';",
            "import 'package:smart_home/constants.dart';\n"
            "import 'package:smart_home/theme/smart_home_colors.dart';",
        )

    s = re.sub(
        r"\n\s*backgroundColor: (bgColor|cardColor|context\.smartColors\.(scaffoldBackground|card)),",
        "",
        s,
    )
    s = s.replace("color: textPrimary", "color: context.smartColors.textPrimary")
    s = s.replace("color: textSecondary", "color: context.smartColors.textSecondary")
    s = s.replace("dropdownColor: cardColor", "dropdownColor: context.smartColors.card")
    s = s.replace("dropdownColor: context.smartColors.card", "dropdownColor: context.smartColors.card")

    with open(path, "w", encoding="utf-8") as f:
        f.write(s)
    print("ok", path)
