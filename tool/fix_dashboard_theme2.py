import re

path = r"lib/screens/dashboard/dashboard_screen.dart"
with open(path, encoding="utf-8") as f:
    s = f.read()

s = s.replace("title: const Text(", "title: Text(")
s = s.replace("subtitle: const Text(", "subtitle: Text(")
s = s.replace("content: const Text(", "content: Text(")
s = s.replace("decoration: const InputDecoration(", "decoration: InputDecoration(")
s = re.sub(r"style: const TextStyle\(", "style: TextStyle(", s)

# Fix builder closures: `        ),\n      );` after AlertDialog actions -> `        );\n      },\n      );`
def fix_dialog_closures(text):
    lines = text.split("\n")
    out = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if (
            i + 1 < len(lines)
            and line.rstrip() == "        ),"
            and lines[i + 1].rstrip() == "      );"
            and i > 0
            and "actions:" in "\n".join(lines[max(0, i - 15) : i + 1])
        ):
            out.append("        );")
            out.append("      },")
            out.append("      );")
            i += 2
            continue
        if (
            i + 1 < len(lines)
            and line.rstrip() == "      ),"
            and lines[i + 1].rstrip() == "    );"
            and i > 0
            and "return SafeArea(" in "\n".join(lines[max(0, i - 40) : i + 1])
        ):
            out.append("      );")
            out.append("    },")
            out.append("    );")
            i += 2
            continue
        out.append(line)
        i += 1
    return "\n".join(out)

s = fix_dialog_closures(s)

with open(path, "w", encoding="utf-8") as f:
    f.write(s)
print("fixed")
