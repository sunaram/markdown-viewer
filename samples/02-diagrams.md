# Diagrams from plain text

Fenced ` ```mermaid ` blocks become live diagrams that follow the light / dark theme.

<div style="display:grid;grid-template-columns:repeat(3,1fr);gap:24px;align-items:start">

<div style="grid-column:span 3">

```mermaid
flowchart LR
  A[Markdown file] --> B{Contains math?}
  B -- yes --> C[LaTeX to MathML]
  B -- no --> D[HTML]
  C --> D
  D --> E[(Web view)]
  E --> F[[Mermaid]]
  F --> G([Rendered])
  style A fill:#2563eb,stroke:#1e40af,color:#fff
  style G fill:#16a34a,stroke:#166534,color:#fff
```

</div>

<div>

```mermaid
stateDiagram-v2
  [*] --> Idle
  Idle --> Rendering: open file
  Rendering --> Idle: done
  Rendering --> Error: read failed
  Error --> Idle: open another
  Idle --> Reloading: file changed
  Reloading --> Idle
  Idle --> [*]: quit
```

</div>

<div>

```mermaid
classDiagram
  class State {
    +Option~PathBuf~ file
    +str theme
  }
  class Settings {
    +str theme
    +f64 zoom
    +Vec~PathBuf~ recent
  }
  class WebView {
    +zoom(f64)
    +print()
  }
  State --> WebView : serves pages to
  Settings ..> State : restores
```

</div>

<div>

```mermaid
%%{init: {"themeVariables": {"pie1": "#2563eb", "pie2": "#7c3aed", "pie3": "#0891b2", "pie4": "#16a34a", "pieOuterStrokeWidth": "0px", "pieStrokeColor": "#ffffff55"}}}%%
pie showData title Binary size by component (KB)
  "Mermaid (compressed)" : 1580
  "Web view glue" : 520
  "Markdown + math" : 250
  "Menus + dialogs" : 130
```

</div>

<div>

```mermaid
sequenceDiagram
  autonumber
  participant U as User
  participant V as mdv
  participant W as Web view
  participant F as Files
  U->>V: Open README.md
  V->>F: read bytes
  F-->>V: Markdown
  V->>W: serve page
  W->>V: GET mermaid.js
  V-->>W: inflate and serve
  W-->>U: Rendered document
  loop every 500 ms
    V->>F: check modified time
  end
  Note over V,F: live reload on change
```

</div>

<div>

```mermaid
erDiagram
  DOCUMENT ||--o{ HEADING : contains
  DOCUMENT ||--o{ EQUATION : contains
  DOCUMENT ||--o{ DIAGRAM : contains
  DIAGRAM {
    string kind
    string source
  }
  EQUATION {
    string latex
    bool display
  }
```

</div>

<div>

```mermaid
mindmap
  root((mdv))
    Markdown
      Tables
      Footnotes
    Math
      LaTeX
      MathML
    Diagrams
      Mermaid
      SVG
    Desktop
      Windows
      Linux
      macOS
```

</div>

<div style="grid-column:span 2">

```mermaid
gantt
  title Release plan
  dateFormat YYYY-MM-DD
  axisFormat %b %d
  section Core
  Markdown + math     :done, a1, 2026-09-01, 10d
  Mermaid + HTML      :done, a2, after a1, 6d
  section Desktop
  Menus + shortcuts   :done, b1, after a2, 5d
  Packaging           :active, b2, after b1, 7d
  section Launch
  Store submission    :c1, after b2, 4d
```

</div>

</div>
