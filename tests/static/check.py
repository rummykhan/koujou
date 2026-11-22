#!/usr/bin/env python3
"""Tier 0: checks that need no model and no beads. Run from anywhere: python3 tests/static/check.py

The factory is prose that agents follow, so the cheap failures are broken references: a skill that names a file,
a worker, a label or a command that does not exist. Everything here is that kind of check."""
import json
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
fails, warns = [], []


def fail(msg):
    fails.append(msg)


def front(path):
    text = path.read_text()
    m = re.match(r"---\n(.*?)\n---\n", text, re.S)
    if not m:
        return None
    return dict(line.split(":", 1) for line in m.group(1).splitlines() if ":" in line and not line.startswith(" "))


skills = {p.parent.name: p for p in sorted(ROOT.glob("skills/*/SKILL.md"))}
agents = {p.stem: p for p in sorted(ROOT.glob("agents/*.md"))}
docs = [*skills.values(), *agents.values(), *sorted(ROOT.glob("skills/factory/reference/*.md")), ROOT / "README.md"]

# 1. frontmatter
for name, path in {**skills, **agents}.items():
    fm = front(path)
    rel = path.relative_to(ROOT)
    if fm is None:
        fail(f"{rel}: no frontmatter")
        continue
    if fm.get("name", "").strip() != name:
        fail(f"{rel}: frontmatter name is {fm.get('name', '').strip()!r}, expected {name!r}")
    desc = fm.get("description", "").strip()
    if not desc:
        fail(f"{rel}: no description")
    elif len(desc) > 1024:
        fail(f"{rel}: description is {len(desc)} characters (limit 1024)")

# 2. every factory-<name> mentioned is a skill or a worker that exists
known = set(skills) | set(agents)
not_names = {"factory-task", "factory-worktrees", "factory-test"}  # branch prefix, directory, the repo's own test skill
for path in docs:
    for word in set(re.findall(r"\bfactory-[a-z]+\b", path.read_text())):
        if word not in known and word not in not_names:
            fail(f"{path.relative_to(ROOT)}: mentions `{word}`, which is neither a skill nor a worker")

# 3. every referenced file exists
for path in docs:
    text = path.read_text()
    for ref in set(re.findall(r"~/\.claude/skills/([\w./-]+\.(?:md|json))", text)):
        if not (ROOT / "skills" / ref).exists():
            fail(f"{path.relative_to(ROOT)}: points to ~/.claude/skills/{ref}, which does not exist")
    for ref in set(re.findall(r"~/\.claude/agents/factory/([\w.-]+\.md)", text)):
        if "<" not in ref and not (ROOT / "agents" / ref).exists():
            fail(f"{path.relative_to(ROOT)}: points to agent file {ref}, which does not exist")
    for ref in set(re.findall(r"\]\((?!https?:|#)([^)\s]+)\)", text)):
        if path.name.endswith("-template.md"):
            continue  # links in a template are relative to the project it is copied into
        if not (path.parent / ref).exists():
            fail(f"{path.relative_to(ROOT)}: link to {ref} is broken")
    for ref in set(re.findall(r"`((?:skills|agents|bin|scripts|docs|tests)/[\w./-]+)`", text)):
        if not (ROOT / ref).exists():
            fail(f"{path.relative_to(ROOT)}: names `{ref}`, which does not exist")

# 4. labels: every factory:<label> used is documented in the beads reference
beads_ref = (ROOT / "skills/factory/reference/beads.md").read_text()
documented = set(re.findall(r"`factory:([a-z-]+)", beads_ref))
for path in docs:
    for label in set(re.findall(r"\bfactory:([a-z][a-z-]*)", path.read_text())):
        if label not in documented and label.rstrip("-") not in documented:
            fail(f"{path.relative_to(ROOT)}: uses label factory:{label}, which beads.md does not document")

# 5. every `koujou <sub>` mentioned is implemented, and every one implemented is in the README
cli = (ROOT / "bin/koujou").read_text()
implemented = set(re.findall(r"^  ([a-z]+)\)", cli, re.M))
for path in docs:
    for sub in set(re.findall(r"`koujou ([a-z]+)\b", path.read_text())):
        if sub not in implemented:
            fail(f"{path.relative_to(ROOT)}: mentions `koujou {sub}`, which bin/koujou does not implement")
readme = (ROOT / "README.md").read_text()
for sub in implemented - {"link"}:
    if f"koujou {sub}" not in readme:
        fail(f"README.md: `koujou {sub}` is implemented but not documented")
for name in skills:
    if name not in ("factory-adopt", "factory-new") and f"/{name}" not in readme:
        fail(f"README.md: skill /{name} is not in the commands table")
for name in agents:
    if name not in readme:
        fail(f"README.md: worker {name} is not in the workers table")

# 6. worker roster is the same everywhere it is listed
for path, pattern in ((skills["factory"], r"\| `(factory-[a-z]+)`(?: \(QA\))? \| Subagent"), (skills["factory-run"], r"subagent types ([^.]*)\.")):
    text = path.read_text()
    listed = set(re.findall(r"factory-[a-z]+", " ".join(re.findall(pattern, text))))
    if listed != set(agents):
        fail(f"{path.relative_to(ROOT)}: lists workers {sorted(listed)}, agents/ has {sorted(agents)}")

# 7. templates and data files
try:
    plan = json.loads((ROOT / "skills/factory/reference/plan-example.json").read_text())
    keys = {n["key"] for n in plan["nodes"]}
    for e in plan["edges"]:
        if e["from_key"] not in keys or e["to_key"] not in keys:
            fail("plan-example.json: an edge names a key that is not a node")
except (ValueError, KeyError) as e:
    fail(f"plan-example.json: {e}")
template = (ROOT / "skills/factory/reference/agents-template.md").read_text()
if template.count("<!-- BEGIN SOFTWARE FACTORY") != 1 or template.count("<!-- END SOFTWARE FACTORY -->") != 1:
    fail("agents-template.md: must contain exactly one BEGIN and one END marker")
profile = (ROOT / "skills/factory/reference/profile-template.md").read_text()
for section in ("Commands", "Git policy", "Deploy policy", "Test map", "QA", "Security review", "Limits", "Lessons"):
    if f"## {section}" not in profile:
        fail(f"profile-template.md: section '## {section}' is missing (skills read it)")
for limit in set(re.findall(r"`(max_[a-z_]+)`", "".join(p.read_text() for p in skills.values()))):
    if limit not in profile:
        fail(f"profile-template.md: skills use `{limit}` but the template does not define it")

# 8. scripts parse
for script in ("bin/koujou", "install.sh"):
    if subprocess.run(["bash", "-n", str(ROOT / script)], capture_output=True).returncode:
        fail(f"{script}: bash syntax error")
for script in sorted(ROOT.glob("bin/*.py")) + sorted(ROOT.glob("scripts/*.py")) + sorted(ROOT.glob("tests/**/*.py")):
    try:
        compile(script.read_text(), str(script), "exec")
    except SyntaxError as e:
        fail(f"{script.relative_to(ROOT)}: {e}")

# 9. scenarios are well formed, and every worker has one
covered = set()
names = {p.name for p in (ROOT / "tests/scenarios").iterdir() if p.is_dir()}
for name in sorted(names):
    d = ROOT / "tests/scenarios" / name
    fm = front(d / "scenario.md") if (d / "scenario.md").exists() else None
    if fm is None:
        fail(f"tests/scenarios/{name}: scenario.md with frontmatter is missing")
        continue
    fm = {k: v.strip() for k, v in fm.items()}
    if fm.get("name") != name:
        fail(f"tests/scenarios/{name}: frontmatter name must be the directory name")
    if fm.get("tier") not in ("module", "demo"):
        fail(f"tests/scenarios/{name}: tier must be module or demo")
    subject = fm.get("subject", "")
    if not subject or not (ROOT / subject).exists():
        fail(f"tests/scenarios/{name}: subject {subject!r} does not exist")
    covered.add(subject)
    for key in ("control", "control-for"):
        if key in fm and fm[key] not in names:
            fail(f"tests/scenarios/{name}: {key} names {fm[key]!r}, which is not a scenario")
    if "## Brief" not in (d / "scenario.md").read_text():
        fail(f"tests/scenarios/{name}: scenario.md has no '## Brief' section")
    for script in ("setup.sh", "expect.sh"):
        f = d / script
        if not f.exists():
            fail(f"tests/scenarios/{name}: {script} is missing")
        elif subprocess.run(["bash", "-n", str(f)], capture_output=True).returncode:
            fail(f"tests/scenarios/{name}/{script}: bash syntax error")
for name, path in agents.items():
    if str(path.relative_to(ROOT)) not in covered:
        warns.append(f"no scenario has agents/{name}.md as its subject")

for w in warns:
    print(f"  warn  {w}")
for f in fails:
    print(f"  FAIL  {f}")
print(f"\n  static: {len(fails)} failed, {len(warns)} warnings")
sys.exit(1 if fails else 0)
