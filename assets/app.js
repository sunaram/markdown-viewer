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
  if (document.querySelector('.mermaid')) {
    var s = document.createElement('script');
    s.src = '/__mermaid.js';
    s.onload = function () {
      var t = document.documentElement.dataset.theme;
      var dark = t ? t == 'dark' : matchMedia('(prefers-color-scheme:dark)').matches;
      mermaid.initialize({ startOnLoad: false, theme: dark ? 'dark' : 'default' });
      mermaid.run();
    };
    document.head.appendChild(s);
  }
})();
