import sys
P = {
 'light': dict(panel='#f6f8fa', panelStroke='#d8dee4', box='#ffffff', stroke='#d0d7de', text='#1f2328', sub='#59636e',
               blue='#0969da', amber='#9a6700', amberBg='#fff8c5', green='#1a7f37', greenBg='#dafbe1', purple='#8250df', purpleBg='#fbefff', red='#cf222e', line='#6e7781'),
 'dark':  dict(panel='#161b22', panelStroke='#30363d', box='#0d1117', stroke='#3d444d', text='#e6edf3', sub='#9198a1',
               blue='#4493f8', amber='#d29922', amberBg='#2e2a1f', green='#3fb950', greenBg='#12261e', purple='#ab7df8', purpleBg='#231f39', red='#f85149', line='#7d8590'),
}
def build(c):
    W, H = 1200, 560
    o = []
    a = o.append
    a(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" role="img" aria-label="Koujou pipeline: raw idea, requirements, design and plan with your approval at each step; then a delivery loop of build, review, merge queue, security review, validate and triage that repeats until shipped by pull request, followed by a retro.">')
    a(f'''<defs>
<marker id="ah" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0 0L10 5L0 10z" fill="{c['line']}"/></marker>
<marker id="ahb" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0 0L10 5L0 10z" fill="{c['blue']}"/></marker>
<marker id="ahr" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0 0L10 5L0 10z" fill="{c['red']}"/></marker>
</defs>
<style>
text{{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI","Noto Sans",Helvetica,Arial,sans-serif}}
.t{{font-size:16px;font-weight:600;fill:{c['text']}}}
.s{{font-size:12.5px;fill:{c['sub']}}}
.m{{font-size:12.5px;font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;fill:{c['blue']}}}
.h{{font-size:11.5px;font-weight:700;letter-spacing:.09em;fill:{c['sub']}}}
.p{{font-size:12px;font-weight:600}}
</style>''')
    def panel(x,y,w,h): a(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="14" fill="{c["panel"]}" stroke="{c["panelStroke"]}"/>')
    def box(x,y,w,h,title,sub,mono=False,accent=None):
        st = accent or c['stroke']
        sw = 1.6 if accent else 1.2
        a(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="10" fill="{c["box"]}" stroke="{st}" stroke-width="{sw}"/>')
        a(f'<text class="t" x="{x+w/2}" y="{y+h/2-4}" text-anchor="middle">{title}</text>')
        a(f'<text class="{"m" if mono else "s"}" x="{x+w/2}" y="{y+h/2+17}" text-anchor="middle">{sub}</text>')
    def pill(cx,y,w,label,fg,bg,h=26):
        a(f'<rect x="{cx-w/2}" y="{y}" width="{w}" height="{h}" rx="{h/2}" fill="{bg}" stroke="{fg}" stroke-width="1.1"/>')
        a(f'<text class="p" x="{cx}" y="{y+h/2+4.2}" text-anchor="middle" fill="{fg}">{label}</text>')
    def line(d,color=None,marker='ah',dash=False):
        col = color or c['line']
        dashattr = 'stroke-dasharray="5 4"' if dash else ''
        a(f'<path d="{d}" fill="none" stroke="{col}" stroke-width="1.6" {dashattr} marker-end="url(#{marker})"/>')

    # ---- row 1: plan
    panel(20,14,1160,172)
    a(f'<text class="h" x="44" y="42">PLAN · YOU APPROVE EACH STEP</text>')
    bw,bh,gap,x0,y1 = 220,66,60,70,56
    r1 = [('Raw idea','whatever you type',False),('Requirements','/factory-spec',True),('Design','/factory-design',True),('Epics + task graph','/factory-plan',True)]
    xs1=[x0+i*(bw+gap) for i in range(4)]
    for (t,s,m),x in zip(r1,xs1): box(x,y1,bw,bh,t,s,m)
    for i in range(3): line(f'M{xs1[i]+bw+4} {y1+bh/2}H{xs1[i+1]-5}')
    for x in xs1[1:]:
        cx=x+bw/2
        a(f'<path d="M{cx} {y1+bh}V{y1+bh+12}" stroke="{c["amber"]}" stroke-width="1.4"/>')
        pill(cx,y1+bh+12,118,'✓ you approve',c['amber'],c['amberBg'])

    # ---- connector plan -> build
    w2,h2,g2,x2,y2 = 132,70,32,42,274
    xs2=[x2+i*(w2+g2) for i in range(7)]
    pcx = xs1[3]+bw/2; bcx = xs2[0]+w2/2
    line(f'M{pcx} {y1+bh+38}V200H{bcx}V{y2-5}', color=c['blue'], marker='ahb')

    # ---- row 2: delivery loop
    a(f'<rect x="20" y="214" width="1160" height="326" rx="14" fill="{c["panel"]}" stroke="{c["panelStroke"]}"/>')
    # redraw the part of the connector that the panel covered
    line(f'M{bcx} 214V{y2-5}', color=c['blue'], marker='ahb')
    a(f'<text class="h" x="{bcx+18}" y="244">DELIVERY LOOP</text>')
    a(f'<text class="m" x="{bcx+140}" y="244">/factory-run</text>')
    r2 = [('Build','parallel worktrees',None),('Review','independent agent',None),('Merge','one lands, rest rebase',None),('Security','3 agents, 3 lenses',None),
          ('Validate','QA · real browser',c['purple']),('Triage','sort the bugs',None),('Ship','PR · merge · deploy',c['green'])]
    for (t,s,acc),x in zip(r2,xs2): box(x,y2,w2,h2,t,s,False,acc)
    # build <-> review
    line(f'M{xs2[0]+w2+4} {y2+h2/2-9}H{xs2[1]-5}')
    line(f'M{xs2[1]-4} {y2+h2/2+9}H{xs2[0]+w2+5}', color=c['red'], marker='ahr')
    for i in range(1,6): line(f'M{xs2[i]+w2+4} {y2+h2/2}H{xs2[i+1]-5}')
    # fix-now loop: triage -> build
    tcx = xs2[5]+w2/2
    ly = 410
    line(f'M{tcx-22} {y2+h2}V{ly}H{bcx}V{y2+h2+5}', color=c['red'], marker='ahr')
    lx=(tcx-22+bcx)/2
    pill(lx,ly-13,270,'fix now · loops while bugs are closing',c['red'],c['box'])
    # defer
    a(f'<path d="M{tcx+22} {y2+h2}V448" fill="none" stroke="{c["line"]}" stroke-width="1.6" stroke-dasharray="5 4" marker-end="url(#ah)"/>')
    pill(tcx+22,452,176,'defer → next phase',c['sub'],c['box'])
    # retro
    scx = xs2[6]+w2/2
    a(f'<path d="M{scx} {y2+h2}V{492}" fill="none" stroke="{c["green"]}" stroke-width="1.6"/>')
    pill(scx-34,492,200,'retro · factory improves itself',c['green'],c['greenBg'])
    # legend
    a(f'<text class="s" x="44" y="470">Agents work in parallel git worktrees; beads tracks every task,</text>')
    a(f'<text class="s" x="44" y="488">dependency and gate. Anything only you can provide is asked for</text>')
    a(f'<text class="s" x="44" y="506">once, up front, and never blocks the rest.</text>')
    a('</svg>')
    return '\n'.join(o)
out = sys.argv[1]
for k in P: open(f'{out}/flow-{k}.svg','w').write(build(P[k]))
