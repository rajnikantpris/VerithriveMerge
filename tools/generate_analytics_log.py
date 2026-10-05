#!/usr/bin/env python3
"""Write docs/analytics_screen_log.txt with screen_view events only."""

from __future__ import annotations

import re
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "lib"
OUT = ROOT / "docs" / "analytics_screen_log.txt"

CALL_RE = re.compile(r"AnalyticsService\.instance\.logScreenView\s*\(")
KV_RE = re.compile(
    r"""(?:screenName|screenClass|pageCategory|elementLocation)\s*:\s*(?P<val>'[^']*'|"[^"]*"|[^,\n]+)"""
)
NAMED = {
    "screenName": "screen_name",
    "screenClass": "screen_class",
    "pageCategory": "page_category",
    "elementLocation": "element_location",
}


def extract_block(text: str, start: int) -> str:
    i = text.find("(", start)
    if i < 0:
        return ""
    depth = 0
    for j in range(i, min(len(text), i + 1500)):
        if text[j] == "(":
            depth += 1
        elif text[j] == ")":
            depth -= 1
            if depth == 0:
                return text[i : j + 1]
    return text[i : i + 400]


def parse_args(block: str) -> dict[str, str]:
    out = {}
    for key, alias in NAMED.items():
        m = re.search(
            rf"{key}\s*:\s*(?P<val>'[^']*'|\"[^\"]*\"|[^,\n]+)",
            block,
        )
        if not m:
            continue
        val = m.group("val").strip().rstrip(",")
        if (val.startswith("'") and val.endswith("'")) or (
            val.startswith('"') and val.endswith('"')
        ):
            val = val[1:-1]
        else:
            val = re.sub(r"\s+", " ", val)
            if len(val) > 80:
                val = val[:77] + "..."
        out[alias] = val
    return out


def scan() -> list[dict]:
    rows = []
    for path in LIB.rglob("*.dart"):
        if any(p in {"build", ".dart_tool"} for p in path.parts):
            continue
        lines = path.read_text(encoding="utf-8", errors="ignore").splitlines()
        kept = []
        kept_nos = []
        for i, line in enumerate(lines, 1):
            if line.lstrip().startswith("//"):
                continue
            kept.append(line)
            kept_nos.append(i)
        text = "\n".join(kept)
        rel = path.relative_to(ROOT).as_posix()
        for match in CALL_RE.finditer(text):
            block = extract_block(text, match.start())
            params = parse_args(block)
            screen = params.get("screen_name") or path.stem
            line_idx = text[: match.start()].count("\n")
            src_line = kept_nos[line_idx] if line_idx < len(kept_nos) else 0
            inner = ", ".join(f"{k}: {v}" for k, v in params.items())
            log = f"Analytics: [screen_view] parameters: {{{inner}}}"
            rows.append(
                {
                    "screen": screen,
                    "log": log,
                    "file": rel,
                    "line": src_line,
                    "group": "professional"
                    if "professional" in rel
                    else ("enduser" if "enduser" in rel or "select_user" in rel else "other"),
                }
            )
    rows.sort(key=lambda r: (r["group"], r["screen"].lower()))
    return rows


def main() -> None:
    rows = scan()
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    lines = [
        "================================================================================",
        "VERITHRIVE — FIREBASE screen_view LOG",
        f"Generated: {now}",
        "Only screen_view events passed to FirebaseAnalytics.logEvent",
        "================================================================================",
        "",
        f"screen_view count: {len(rows)}",
        "",
    ]

    current = None
    group_titles = {
        "enduser": "END USER SCREENS",
        "professional": "PROFESSIONAL SCREENS",
        "other": "SHARED / OTHER",
    }
    last_group = None
    for row in rows:
        if row["group"] != last_group:
            last_group = row["group"]
            lines.append("-" * 80)
            lines.append(group_titles.get(last_group, last_group.upper()))
            lines.append("-" * 80)
            lines.append("")
            current = None
        if row["screen"] != current:
            current = row["screen"]
            lines.append(f"[SCREEN] {current}")
        lines.append(f"  {row['log']}")
        lines.append(f"      file: {row['file']}:{row['line']}")
        lines.append("")

    lines.extend(
        [
            "-" * 80,
            "LIST",
            "-" * 80,
            "",
        ]
    )
    seen = []
    for row in rows:
        if row["screen"] not in seen:
            seen.append(row["screen"])
            lines.append(f"  {row['screen']}")
    lines.append("")
    lines.append("================================================================================")
    lines.append("")

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {OUT}")
    print(f"screen_view count: {len(rows)}")


if __name__ == "__main__":
    main()
