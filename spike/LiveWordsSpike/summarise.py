import json, sys, os, statistics as st

D = sys.argv[1]  # folder holding run-<mode>.jsonl

def q(xs, p):
    xs = sorted(xs)
    if not xs: return float('nan')
    return xs[min(len(xs) - 1, int(round(p * (len(xs) - 1))))]

def ms(xs):
    return f"{q(xs,.5)*1000:.0f} / {q(xs,.9)*1000:.0f} ms" if xs else "n/a"

def rows(m):
    p = f"{D}/run-{m}.jsonl"
    if not os.path.exists(p): return None, []
    allr = [json.loads(l) for l in open(p)]
    return allr, [r for r in allr if 'clip' in r]

for m in ['a', 'b160', 'b320', 'ab160', 'ab320', 'u320', 'u640', 'u1120', 'ufinal']:
    allr, c = rows(m)
    if not c: continue
    print(f"\n### {m}  clips={len(c)}")
    for r in allr:
        if 'kind' in r: print("  ", {k: (round(v, 2) if isinstance(v, float) else v) for k, v in r.items()})
    good = [r['firstGoodLiveSec'] for r in c if r['firstGoodLiveSec'] > -999]
    anyl = [r['firstLiveSec'] for r in c if r['firstLiveSec'] > -999]
    print("  first matching live word after speech start (median/p90):", ms(good), f"clips with one: {len(good)}/{len(c)}")
    print("  first any live word after speech start:", ms(anyl))
    print("  clips showing words before speech:", sum(r['updatesWithWordsBeforeSpeech'] > 0 for r in c))
    iv = [x for r in c for x in r['updateIntervals']]
    print("  update interval:", ms(iv))
    pc = [(x, a) for r in c for x, a in zip(r['passCompute'], r['passAudioSec'])]
    if pc:
        print("  TDT preview pass, all:", ms([x for x, _ in pc]), "n=", len(pc))
        print("  TDT preview pass, buffer <=15 s:", ms([x for x, a in pc if a <= 15]))
        print("  TDT preview pass, buffer >15 s:", ms([x for x, a in pc if a > 15]), "max", f"{max(x for x,_ in pc)*1000:.0f} ms")
        for lo, hi in [(15, 30), (30, 60), (60, 90)]:
            sel = [x for x, a in pc if lo < a <= hi]
            if sel: print(f"     buffer {lo}-{hi} s:", ms(sel))
        late = [x for r in c for x in r['passLate']]
        print("  passes that ran past the next 1 s tick:", len(late), "of", len(pc), (f"max late {max(late)*1000:.0f} ms" if late else ""))
    ep = [x for r in c for x in r['eouProc']]
    if ep:
        print("  streaming process per 100 ms buffer:", ms(ep), " worst lag behind audio p90/max:",
              f"{q([r['eouLagMax'] for r in c],.9)*1000:.0f} / {max(r['eouLagMax'] for r in c)*1000:.0f} ms")
    wc = [r for r in c if r['refWords'] > 0]
    print("  live vs final WER (pooled):", f"{100*sum(r['liveEdits'] for r in wc)/sum(r['refWords'] for r in wc):.1f}%",
          " per-clip median:", f"{100*st.median(r['liveEdits']/r['refWords'] for r in wc):.1f}%",
          " p90:", f"{100*q([r['liveEdits']/r['refWords'] for r in wc],.9):.1f}%")
    for lo, hi, name in [(0, 5, 'short'), (5, 25.1, 'typical'), (40, 100, 'long')]:
        sel = [r for r in wc if lo <= r['audioSec'] < hi]
        if sel:
            print(f"     {name}: pooled {100*sum(r['liveEdits'] for r in sel)/max(1,sum(r['refWords'] for r in sel)):.1f}%")
    fr = [r['flickerEvents'] / r['liveUpdates'] for r in c if r['liveUpdates'] > 0]
    print("  updates that changed already-shown words, per clip median/p90:", f"{100*q(fr,.5):.0f}% / {100*q(fr,.9):.0f}%",
          " clips with any:", sum(r['flickerEvents'] > 0 for r in c),
          " rewritten words per clip median/p90:", q([r['rewrittenWords'] for r in c], .5), "/", q([r['rewrittenWords'] for r in c], .9))
    print("  live updates per clip median:", q([r['liveUpdates'] for r in c], .5))
    if 'aLiveEdits' in c[0]:
        print("  (A inside ab) WER pooled:", f"{100*sum(r['aLiveEdits'] for r in wc)/sum(r['refWords'] for r in wc):.1f}%",
              " flicker per clip median:", f"{100*q([r['aFlickerEvents']/r['aLiveUpdates'] for r in c if r['aLiveUpdates']],.5):.0f}%")
    rf = [r['releaseToFinalSec'] for r in c]
    print("  release to final text (compute only):", ms(rf), " model's own processingTime:", ms([r['finalComputeSec'] for r in c]))
    for lo, hi, name in [(0, 15.01, '<=15 s'), (15.01, 100, '>15 s')]:
        print(f"     {name}:", ms([r['releaseToFinalSec'] for r in c if lo <= r['audioSec'] < hi]))
    print("  preview in flight at release:", sum(r['previewInFlightAtRelease'] for r in c), " final errors:", sum(bool(r['finalError']) for r in c))
    print("  footprint max during clips:", f"{max(r['footprintMB'] for r in c):.0f} MB")
    if 'uFinalSec' in c[0]:
        print("  Unified offline final pass:", ms([r['uFinalSec'] for r in c]), " errors:", sum(bool(r['uFinalError']) for r in c))
        for lo, hi, name in [(0, 15.01, '<=15 s'), (15.01, 100, '>15 s')]:
            print(f"     {name}:", ms([r['uFinalSec'] for r in c if lo <= r['audioSec'] < hi]))
        print("  Unified final vs TDT final WER (pooled):", f"{100*sum(r['uFinalEdits'] for r in wc)/sum(r['refWords'] for r in wc):.1f}%",
              " per-clip median:", f"{100*st.median(r['uFinalEdits']/r['refWords'] for r in wc):.1f}%",
              " p90:", f"{100*q([r['uFinalEdits']/r['refWords'] for r in wc],.9):.1f}%")
        for lo, hi, name in [(0, 5, 'short'), (5, 25.1, 'typical'), (40, 100, 'long')]:
            sel = [r for r in wc if lo <= r['audioSec'] < hi]
            if sel:
                print(f"     {name}: pooled {100*sum(r['uFinalEdits'] for r in sel)/max(1,sum(r['refWords'] for r in sel)):.1f}%")

allr, c = rows('boost')
if c:
    print("\n### boost  clips=", len(c))
    for r in allr:
        if 'kind' in r: print("  ", {k: (round(v, 2) if isinstance(v, float) else v) for k, v in r.items()})
    print("  final pass, no live words:", ms([r['finalSec'] for r in c]))
    print("     <=15 s:", ms([r['finalSec'] for r in c if r['audioSec'] <= 15]), " >15 s:", ms([r['finalSec'] for r in c if r['audioSec'] > 15]))
    print("  candidate check:", ms([r['checkSec'] for r in c]))
    print("  rescore when run:", ms([r['rescoreSec'] for r in c]))
    print("     <=15 s:", ms([r['rescoreSec'] for r in c if r['audioSec'] <= 15]), " >15 s:", ms([r['rescoreSec'] for r in c if r['audioSec'] > 15]))
    eff = [r['checkSec'] + (r['rescoreSec'] if r['hasCandidates'] else 0) for r in c]
    print("  added with skip check:", ms(eff))
    print("  clips skipped by check:", sum(not r['hasCandidates'] for r in c), " modified:", sum(r['modified'] for r in c))

allr, _ = rows('load')
if allr:
    print("\n### load")
    for r in allr: print("  ", {k: (round(v, 2) if isinstance(v, float) else v) for k, v in r.items()})

allr, _ = rows('stress')
if allr:
    print("\n### stress")
    for r in allr: print("  ", r)
