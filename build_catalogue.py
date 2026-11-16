# @noindex
"""
Builds CATALOGUE.md: every package of the Todoroki ReaPack, with its README
(or, when there is none, the @about text of its ReaPack header).

Run by the "ReaPack index" GitHub Action after reapack-index, so the catalogue
follows index.xml. Locally:  python .github/scripts/build_catalogue.py . CATALOGUE.md

New packages are picked up automatically from index.xml. To give one a nicer
title, a family, or a README stored elsewhere, add it to OVERRIDES below.
"""
import re
import sys
import pathlib
import xml.etree.ElementTree as ET

ROOT = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ".")
OUT = pathlib.Path(sys.argv[2] if len(sys.argv) > 2 else ROOT / "CATALOGUE.md")
REPO_URL = "https://github.com/kazenotodoroki/todoroki-reapack/raw/main/index.xml"

FAMILIES = ["Mixing & referencing", "Composition", "Drums", "Sampling (building instruments)",
            "Effects", "Tools", "Other scripts", "Other effects", "Python utilities"]

# package name in index.xml -> title / family / readme
#   readme: path of the README, or "see:<package name>" when another package holds the docs
OVERRIDES = {
    "RefLab.jsfx": dict(title="RefLab (JSFX)", family="Mixing & referencing",
                        readme="Scripts/RefLab/Todoroki_RefLab README.md"),
    "Todoroki_Companion_Module_RefLab.lua": dict(title="RefLab actions and Companion module",
                                                 family="Mixing & referencing", readme="see:RefLab.jsfx"),
    "Todoroki_Companion.lua": dict(title="Todoroki Companion", family="Mixing & referencing"),
    "Todoroki_ChordMachineGun.lua": dict(title="ChordMachineGun", family="Composition"),
    "RS Trig Sampler.jsfx": dict(title="RS Trig Sampler (JSFX)", family="Drums",
                                 readme="Scripts/RS Trig Sampler/Todoroki_RS Trig Sampler README.md"),
    "Todoroki_RS Trig Kit Builder.lua": dict(title="RS Trig Kit Builder", family="Drums",
                                             readme="see:RS Trig Sampler.jsfx"),
    "Todoroki_Sampling_01_Regions_Creator.lua": dict(title="Sampling 01: Regions Creator", family="Sampling (building instruments)"),
    "Todoroki_Sampling_02_Session_Cleaner.lua": dict(title="Sampling 02: Session Cleaner", family="Sampling (building instruments)"),
    "Todoroki_Sampling_03_Loops_Creator.lua": dict(title="Sampling 03: Loops Creator", family="Sampling (building instruments)"),
    "Todoroki_Sampling_04_Select_Regions_to_export.lua": dict(title="Sampling 04: Select Regions to export", family="Sampling (building instruments)"),
    "Todoroki_Sampling_05_Reaper_To_DS.py": dict(title="Sampling 05: Reaper To DecentSampler (Python)", family="Sampling (building instruments)"),
    "Todoroki_Sampling_05_Reaper_To_Kontakt.py": dict(title="Sampling 05: Reaper To Kontakt (Python)", family="Sampling (building instruments)"),
    "Todoroki_DS-8 Distortion Compressor.jsfx": dict(title="DS-8 Distortion Compressor (JSFX)", family="Effects"),
    "Todoroki_Param Sweep.lua": dict(title="Param Sweep", family="Tools"),
    "Todoroki_ZLEQ2 Curve Import.lua": dict(title="ZLEQ2 Curve Import", family="Tools"),
    "Todoroki_Portable Backup.lua": dict(title="Portable Backup", family="Tools"),
    "Todoroki_FXLISTER_FX Param_idx_Lister.lua": dict(title="FX Param_idx Lister", family="Tools",
        note="Use it with **FX Lua Creator**: the list printed in the console is pasted into the Python tool."),
    "Todoroki_FXLIST_FX_lua_Creator.py": dict(title="FX Lua Creator (Python)", family="Tools"),
}

EXTRAS = [  # files outside ReaPack, listed only when they exist
    ("Stream Deck/Todoroki RefLab.streamDeckIconPack",
     "Stream Deck icon pack for the RefLab actions (sources in `Stream Deck/com.todoroki.reflab.sdIconPack/`)."),
    ("Scripts/RS Trig Sampler/Todoroki_RS Trig TCI Converter.html",
     "Web page (Chrome / Edge) that converts a whole Slate Trigger 2 library; installed with RS Trig Kit Builder."),
    ("AIDE-MEMOIRE.txt", "Repository rules: where to put files, header template, how to publish an update."),
]


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8", errors="replace")


def header_tag(text, tag):
    """Value of a ReaPack header tag (@about, @description...), comment prefixes removed."""
    lines, on = [], False
    for ln in text.splitlines()[:200]:
        m = re.match(r"^\s*(--|#|//)\s?(.*)$", ln)
        if not m:
            if on:
                break
            continue
        body = m.group(2)
        t = re.match(r"@(\w+)\s*(.*)$", body)
        if t:
            if on:
                break
            if t.group(1) == tag:
                on = True
                if t.group(2):
                    lines.append(t.group(2))
            continue
        if on:
            lines.append(re.sub(r"^  ", "", body))
    return "\n".join(lines).strip()


def strip_h1(md):
    return re.sub(r"\A#\s+[^\n]*\n+", "", md.strip())


def demote(md, n=2):
    out, code = [], False
    for ln in md.splitlines():
        if ln.lstrip().startswith("```"):
            code = not code
        if not code and re.match(r"^#{1,6} ", ln):
            ln = "#" * min(6, ln.index(" ") + n) + ln[ln.index(" "):]
        out.append(ln)
    return "\n".join(out).strip()


def anchor(s):
    return "pkg-" + re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")


def find_readme(folder):
    if folder in ("", ".") or "/" not in folder:  # flat category folder: README would be shared
        return None
    hits = sorted((ROOT / folder).glob("*README.md"))
    return str(hits[0].relative_to(ROOT)).replace("\\", "/") if hits else None


# ---------------------------------------------------------------- collect packages
items = []
index = ET.parse(ROOT / "index.xml").getroot()
for cat in index.iter("category"):
    for p in cat.findall("reapack"):
        name, cname = p.get("name"), cat.get("name")
        v = p.findall("version")[-1]
        main = f"{cname}/{name}"
        o = OVERRIDES.get(name, {})
        desc = p.get("desc") or name
        is_py = name.endswith(".py")
        family = o.get("family") or ("Python utilities" if is_py else
                                     "Other effects" if p.get("type") == "effect" else "Other scripts")
        items.append(dict(
            key=name, title=o.get("title") or desc.split(" - ")[0].strip(), family=family,
            kind="Python (external)" if is_py else "JSFX" if p.get("type") == "effect" else "Lua script",
            version=v.get("name"), date=(v.get("time") or "")[:10], files=len(v.findall("source")),
            main=main, readme=o.get("readme", find_readme(cname)), note=o.get("note"), beta=False))

# Beta folders (not published, @noindex): one entry per folder that has a README
for d in sorted((ROOT / "Beta").glob("*/")) if (ROOT / "Beta").is_dir() else []:
    readmes = sorted(d.glob("*README.md"))
    if not readmes:
        continue
    rel = str(readmes[0].relative_to(ROOT)).replace("\\", "/")
    h1 = re.match(r"#\s+(.+)", read(rel).strip())
    title = h1.group(1).strip() if h1 else d.name
    items.append(dict(key="beta:" + d.name, title=title, family="Composition" if "Chord" in d.name else "Other scripts",
                      kind="Lua script", version="beta", date="", files=None,
                      main=str(d.relative_to(ROOT)).replace("\\", "/") + "/", readme=rel,
                      note=f"Not published through ReaPack yet (every file is `@noindex`): install it by hand from `{d.relative_to(ROOT).as_posix()}/`.",
                      beta=True))

fam_rank = {f: i for i, f in enumerate(FAMILIES)}
order = {k: i for i, k in enumerate(OVERRIDES)}
items.sort(key=lambda it: (fam_rank.get(it["family"], 99), it["beta"], order.get(it["key"], 999), it["title"].lower()))
by_key = {it["key"]: it for it in items}

# ---------------------------------------------------------------- write
o = []
w = o.append
latest = max((it["date"] for it in items if it["date"]), default="")
w("# Todoroki ReaPack catalogue\n")
w("Every package of the **todoroki-reapack** repository, with its documentation compiled in one place "
  "(the package README, or the `@about` text of its ReaPack header when it has no README).\n")
w(f"ReaPack repository: `{REPO_URL}` (*Extensions → ReaPack → Import repositories*).\n")
w("_This file is generated automatically by `.github/scripts/build_catalogue.py` on every push: "
  "do not edit it by hand, edit the READMEs and script headers instead._"
  + (f" Latest package update: {latest}." if latest else "") + "\n")

w("## Contents\n")
w("| Family | Package | Type | Version | Files | Docs |")
w("|---|---|---|---|---|---|")
for it in items:
    files = "–" if it["files"] is None else str(it["files"])
    docs = "README" if it["readme"] else "@about"
    ver = "beta (unpublished)" if it["beta"] else it["version"]
    w(f"| {it['family']} | [{it['title']}](#{anchor(it['key'])}) | {it['kind']} | {ver} | {files} | {docs} |")
w("")
w("*Files*: number of files installed by the ReaPack package (actions, icons, modules…).\n")

cur = None
for it in items:
    if it["family"] != cur:
        cur = it["family"]
        w("---\n")
        w(f"## {cur}\n")
    w(f'<a id="{anchor(it["key"])}"></a>\n')
    w(f"### {it['title']}\n")
    meta = [f"**Main file**: `{it['main']}`"]
    if not it["beta"]:
        meta.append(f"**Version**: {it['version']}" + (f" ({it['date']})" if it["date"] else ""))
    rd = it["readme"]
    if rd and not rd.startswith("see:"):
        meta.append(f"**README**: `{rd}`")
    w("  \n".join(meta) + "\n")
    if it["note"]:
        w(f"> {it['note']}\n")
    if rd and rd.startswith("see:"):
        ref = by_key.get(rd[4:])
        if ref:
            w(f"Full documentation: see [{ref['title']}](#{anchor(ref['key'])}).\n")
        rd = None
        body = header_tag(read(it["main"]), "about")
    elif rd and (ROOT / rd).is_file():
        body = read(rd)
    else:
        body = header_tag(read(it["main"]), "about") if (ROOT / it["main"]).is_file() else ""
    body = demote(strip_h1(body), 2) if body else "_No description yet._"
    w(body + "\n")

extras = [(p, d) for p, d in EXTRAS if (ROOT / p).exists()]
if extras:
    w("---\n")
    w("## Extras (not installed by ReaPack)\n")
    for p, d in extras:
        w(f"- `{p}`: {d}")
    w("")

OUT.write_text("\n".join(o) + "\n", encoding="utf-8", newline="\n")
print(f"{OUT}: {len(items)} packages")
