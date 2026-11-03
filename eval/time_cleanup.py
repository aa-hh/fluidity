#!/usr/bin/env python3
"""Times Rillo's cleanup request against each cloud provider (AA-465).

Sends the same system message Rillo sends (rules and examples read from the
Swift sources) with three made-up transcripts, over one kept-open connection
per provider, the way CleanupClient does after warm-up. Reports how long each
full reply took and how many finished inside 1, 2 and 3 seconds.

Keys come from CEREBRAS_API_KEY, OPENAI_API_KEY and ANTHROPIC_API_KEY. The
Cerebras key falls back to the one Rillo keeps in the Keychain. A provider
with no key is skipped.

    python3 eval/time_cleanup.py --runs 10
    python3 eval/time_cleanup.py --providers openai --openai-effort low
    python3 eval/time_cleanup.py --print-request   # show bodies, send nothing
"""

import argparse
import http.client
import json
import os
import re
import statistics
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SETTINGS = ROOT / "RilloCore/Sources/RilloCore/Settings/Settings.swift"
PROMPT = ROOT / "RilloCore/Sources/RilloCore/CleanupClient/CleanupPrompt.swift"

# Made up, so nothing private leaves the Mac.
TRANSCRIPTS = {
    "short": "um can you send me the notes from yesterday",
    "medium": (
        "so I was thinking we should uh move the standup to ten instead of nine "
        "because half the team is in a different time zone now and no actually "
        "make it ten thirty so people have time to get coffee first"
    ),
    "long": (
        "okay so for the release there are three things first we need to finish "
        "the settings pane and um make sure the key field shows an error when the "
        "key is wrong second the website needs the new pricing and the the "
        "screenshots from the latest build third we have to test it on an older "
        "Mac because last time it was really slow on the intel machines and nobody "
        "noticed until a customer emailed us also can you remind me to book the "
        "flights for the conference I think it's the second week of December or "
        "maybe the third I'll check and let you know thumbs up emoji"
    ),
}

SCHEMA = {
    "type": "object",
    "properties": {"cleaned": {"type": "string"}},
    "required": ["cleaned"],
    "additionalProperties": False,
}


def swift_unescape(s):
    return re.sub(r'\\(.)', lambda m: {"n": "\n", "t": "\t"}.get(m.group(1), m.group(1)), s)


def default_rules():
    """The multi-line string in Settings.swift, with Swift's line rules applied."""
    src = SETTINGS.read_text()
    body = re.search(r'defaultCleanupRules = """\n(.*?)\n(\s*)"""', src, re.S)
    indent = len(body.group(2))
    lines = [line[indent:] for line in body.group(1).split("\n")]
    # A trailing backslash joins the line to the next with no newline.
    return swift_unescape(re.sub(r"\\\n", "", "\n".join(lines)))


def examples():
    src = PROMPT.read_text()
    block = src[src.index("examples:"):src.index("static func systemMessage")]
    pairs = re.findall(r'\("((?:[^"\\]|\\.)*)",\s*"((?:[^"\\]|\\.)*)"\)', block)
    return [(swift_unescape(a), swift_unescape(b)) for a, b in pairs]


def as_json(obj):
    # Matches JSONSerialization with .sortedKeys and .withoutEscapingSlashes.
    return json.dumps(obj, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def system_message():
    """Same as CleanupPrompt.systemMessage with an empty word list."""
    message = default_rules() + "\n\nExamples:"
    for transcript, cleaned in examples():
        message += "\n\nInput: " + as_json({"transcript": transcript})
        message += "\nOutput: " + as_json({"cleaned": cleaned})
    return message


def openai_format_body(model, effort, transcript, cerebras):
    body = {
        "model": model,
        "messages": [
            {"role": "system", "content": system_message()},
            {"role": "user", "content": as_json({"transcript": transcript})},
        ],
        "response_format": {
            "type": "json_schema",
            "json_schema": {"name": "cleanup", "strict": True, "schema": SCHEMA},
        },
    }
    if effort:
        body["reasoning_effort"] = effort
    if cerebras:  # Exactly what CleanupClient sends today.
        body["temperature"] = 0
        body["reasoning_format"] = "hidden"
    return body


def anthropic_body(model, effort, transcript):
    return {
        "model": model,
        "max_tokens": 1024,
        "system": system_message(),
        "messages": [{"role": "user", "content": as_json({"transcript": transcript})}],
        "thinking": {"type": "disabled"},
        "output_config": {"effort": effort, "format": {"type": "json_schema", "schema": SCHEMA}},
    }


def cleaned_from(provider, reply):
    if provider == "anthropic":
        if reply.get("stop_reason") != "end_turn":
            raise ValueError(f"stop_reason {reply.get('stop_reason')}")
        text = "".join(b.get("text", "") for b in reply["content"] if b["type"] == "text")
    else:
        choice = reply["choices"][0]
        if choice.get("finish_reason") != "stop":
            raise ValueError(f"finish_reason {choice.get('finish_reason')}")
        text = choice["message"]["content"]
    return json.loads(text)["cleaned"]


class Provider:
    def __init__(self, name, host, base, headers, make_body, path):
        self.name, self.host, self.base, self.headers = name, host, base, headers
        self.make_body, self.path = make_body, path
        self.conn = None

    def send(self, method, path, body=None):
        if self.conn is None:
            self.conn = http.client.HTTPSConnection(self.host, timeout=30)
        data = json.dumps(body).encode() if body is not None else None
        try:
            self.conn.request(method, self.base + path, body=data, headers=self.headers)
            resp = self.conn.getresponse()
            return resp.status, resp.read()
        except (http.client.HTTPException, OSError):
            self.conn.close()
            self.conn = None
            raise

    def warm_up(self):
        self.send("GET", "/models")


def keychain_cerebras_key():
    try:
        out = subprocess.run(
            ["security", "find-generic-password", "-s", "com.rillo.app", "-a", "cleanupAPIKey", "-w"],
            capture_output=True, text=True, check=True,
        )
        return out.stdout.strip() or None
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None


def providers(args):
    found = []
    if "cerebras" in args.providers:
        key = os.environ.get("CEREBRAS_API_KEY") or keychain_cerebras_key()
        found.append((key, Provider(
            "cerebras", "api.cerebras.ai", "/v1",
            {"Authorization": f"Bearer {key}", "Content-Type": "application/json"},
            lambda t: openai_format_body(args.cerebras_model, "low", t, cerebras=True),
            "/chat/completions",
        )))
    if "openai" in args.providers:
        key = os.environ.get("OPENAI_API_KEY")
        found.append((key, Provider(
            "openai", "api.openai.com", "/v1",
            {"Authorization": f"Bearer {key}", "Content-Type": "application/json"},
            lambda t: openai_format_body(args.openai_model, args.openai_effort, t, cerebras=False),
            "/chat/completions",
        )))
    if "anthropic" in args.providers:
        key = os.environ.get("ANTHROPIC_API_KEY")
        found.append((key, Provider(
            "anthropic", "api.anthropic.com", "/v1",
            {"x-api-key": f"{key}", "anthropic-version": "2026-10-21", "Content-Type": "application/json"},
            lambda t: anthropic_body(args.anthropic_model, args.anthropic_effort, t),
            "/messages",
        )))
    return found


def time_provider(p, runs):
    p.warm_up()
    times, failures = [], []
    for run in range(runs):
        for label, transcript in TRANSCRIPTS.items():
            start = time.perf_counter()
            try:
                status, raw = p.send("POST", p.path, p.make_body(transcript))
                elapsed = time.perf_counter() - start
                if status != 200:
                    raise ValueError(f"HTTP {status}: {raw[:300].decode(errors='replace')}")
                cleaned = cleaned_from(p.name, json.loads(raw))
            except Exception as e:  # noqa: BLE001 - every failure is reported, none stops the others
                failures.append(f"{label}: {e}")
                # A rejected request fails the same way every time; stop spending on it.
                if len(failures) >= 2 and not times:
                    return times, failures
                continue
            times.append(elapsed)
            if run == 0:
                print(f"  {label:6} {elapsed:5.2f} s  {cleaned[:70]!r}")
    return times, failures


def report(name, times, failures):
    if times:
        times.sort()
        p90 = times[min(len(times) - 1, int(len(times) * 0.9))]
        within = "  ".join(f"<{s} s: {sum(t < s for t in times)}/{len(times)}" for s in (1, 2, 3))
        print(f"  median {statistics.median(times):.2f} s  p90 {p90:.2f} s  max {times[-1]:.2f} s  {within}")
    for f in failures[:3]:
        print(f"  failed {f}")
    if len(failures) > 3:
        print(f"  ...and {len(failures) - 3} more failures")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--providers", nargs="+", default=["cerebras", "openai", "anthropic"],
                    choices=["cerebras", "openai", "anthropic"])
    ap.add_argument("--runs", type=int, default=5, help="rounds of the three transcripts per provider")
    ap.add_argument("--cerebras-model", default="gpt-oss-120b")
    ap.add_argument("--openai-model", default="gpt-6-luna")
    ap.add_argument("--openai-effort", default="none", help='sent as reasoning_effort; "" to leave it out')
    ap.add_argument("--anthropic-model", default="claude-haiku-5-5")
    ap.add_argument("--anthropic-effort", default="low")
    ap.add_argument("--print-request", action="store_true", help="print each request body and exit")
    args = ap.parse_args()

    for key, p in providers(args):
        if args.print_request:
            print(f"--- {p.name} POST https://{p.host}{p.base}{p.path}")
            print(json.dumps(p.make_body(TRANSCRIPTS["short"]), indent=2, ensure_ascii=False))
            continue
        if not key:
            print(f"{p.name}: skipped, no key")
            continue
        print(f"{p.name}:")
        times, failures = time_provider(p, args.runs)
        report(p.name, times, failures)


if __name__ == "__main__":
    sys.exit(main())
