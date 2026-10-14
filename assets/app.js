(function () {
  var mac = /Mac/.test(navigator.platform), bar, inp;
  function send(c) { window.ipc.postMessage(c); }
  function find(back) { if (inp && inp.value) window.find(inp.value, false, back, true); }
  window.__find = function () {
    if (!bar) {
      bar = document.createElement('div');
      bar.id = 'find';
      bar.innerHTML = '<input placeholder="Find (Enter / Shift+Enter)">';
      document.body.appendChild(bar);
      inp = bar.firstChild;
      inp.onkeydown = function (e) {
        if (e.key == 'Enter') find(e.shiftKey);
        else if (e.key == 'Escape') bar.style.display = 'none';
      };
    }
    bar.style.display = 'block';
    inp.focus();
    inp.select();
  };
  var keys = { o: 'open', r: 'reload', p: 'print', e: 'editor', w: 'quit', '=': 'zin', '+': 'zin', '-': 'zout', '0': 'zreset' };
  addEventListener('keydown', function (e) {
    if (e.key == 'F3') { e.preventDefault(); find(e.shiftKey); return; }
    if (e.key == 'F5') { e.preventDefault(); send('reload'); return; }
    if (e.key == 'Escape' && bar && bar.style.display != 'none') { bar.style.display = 'none'; return; }
    if (!(e.ctrlKey || e.metaKey)) return;
    var k = e.key.toLowerCase();
    if (k == 'f') { e.preventDefault(); __find(); return; }
    // on macOS the native menu accelerators handle the rest
    if (!mac && keys[k]) { e.preventDefault(); send(keys[k]); }
  });
  // plain-text fallback for labels that cannot hold MathML (SVG <text>): TeX -> readable Unicode
  var SYM = { alpha: 'α', beta: 'β', gamma: 'γ', delta: 'δ', epsilon: 'ε', varepsilon: 'ε', zeta: 'ζ', eta: 'η', theta: 'θ', lambda: 'λ', mu: 'μ', nu: 'ν', xi: 'ξ', pi: 'π', rho: 'ρ', sigma: 'σ', tau: 'τ', phi: 'φ', varphi: 'φ', chi: 'χ', psi: 'ψ', omega: 'ω', Gamma: 'Γ', Delta: 'Δ', Theta: 'Θ', Lambda: 'Λ', Pi: 'Π', Sigma: 'Σ', Phi: 'Φ', Psi: 'Ψ', Omega: 'Ω', infty: '∞', partial: '∂', nabla: '∇', sum: '∑', prod: '∏', int: '∫', times: '×', cdot: '·', pm: '±', leq: '≤', le: '≤', geq: '≥', ge: '≥', neq: '≠', ne: '≠', approx: '≈', equiv: '≡', to: '→', rightarrow: '→', leftarrow: '←', Rightarrow: '⇒', in: '∈', forall: '∀', exists: '∃', sqrt: '√', ldots: '…', cdots: '⋯', hbar: 'ħ' };
  var SUP = '⁰¹²³⁴⁵⁶⁷⁸⁹', SUB = '₀₁₂₃₄₅₆₇₈₉';
  function uni(t) {
    var r = t.replace(/\\(?:d|t)?frac\s*\{([^{}]*)\}\s*\{([^{}]*)\}/g, '($1)/($2)')
      .replace(/\\([A-Za-z]+)/g, function (m, n) { return SYM[n] || n; })
      .replace(/\^\{?(\d+)\}?/g, function (m, d) { return d.replace(/\d/g, function (c) { return SUP[c]; }); })
      .replace(/_\{?(\d+)\}?/g, function (m, d) { return d.replace(/\d/g, function (c) { return SUB[c]; }); });
    return r.replace(/[{}]/g, '');
  }
  // swap the mdvm<n>z placeholders (see mermaid_math in main.rs) for the typeset formulas
  function typeset() {
    document.querySelectorAll('.mermaid[data-m]').forEach(function (pre) {
      var items = JSON.parse(pre.dataset.m);
      var w = document.createTreeWalker(pre, NodeFilter.SHOW_TEXT), nodes = [], n;
      while ((n = w.nextNode())) if (/mdvm\d+z/.test(n.nodeValue)) nodes.push(n);
      nodes.forEach(function (t) {
        var html = !!t.parentElement.closest('foreignObject'), frag = document.createDocumentFragment();
        t.nodeValue.split(/(mdvm\d+z)/).forEach(function (part) {
          var m = /^mdvm(\d+)z$/.exec(part), it = m && items[+m[1]];
          if (!it) { if (part) frag.appendChild(document.createTextNode(part)); return; }
          if (html) {
            var s = document.createElement('span');
            s.innerHTML = it[0];
            frag.appendChild(s);
          } else frag.appendChild(document.createTextNode(uni(it[1])));
        });
        t.parentNode.replaceChild(frag, t);
      });
    });
  }
  if (document.querySelector('.mermaid')) {
    var s = document.createElement('script');
    s.src = '/__mermaid.js';
    s.onload = function () {
      var t = document.documentElement.dataset.theme;
      var dark = t ? t == 'dark' : matchMedia('(prefers-color-scheme:dark)').matches;
      mermaid.initialize({ startOnLoad: false, theme: dark ? 'dark' : 'default' });
      mermaid.run().then(typeset);
    };
    document.head.appendChild(s);
  }
})();
