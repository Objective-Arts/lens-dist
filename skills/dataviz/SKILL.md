---
name: dataviz
description: Build D3 visualizations with Bostock's patterns, Tufte's integrity, Few's clarity, and production-grade frontend craft.
---

# /dataviz

Build data visualizations that are technically correct, visually honest, and worth looking at. Combines Bostock (D3 patterns), Tufte (graphical integrity), Few (information design), and frontend craft into one workflow.

> **No arguments?** Describe this skill and stop. Do not execute.

## Before You Write Code

Answer these questions. They determine everything.

### 1. What decision does this visualization support?

If you can't name the decision, you don't need a visualization — you need a table. Every chart exists to help someone decide or understand something specific.

### 2. What type of data relationship?

| Relationship | Best Display | Never Use |
|-------------|-------------|-----------|
| Comparison | Horizontal bar (sorted) | Pie, radar |
| Trend over time | Line, area, sparkline | Bar (unless discrete periods) |
| Distribution | Histogram, strip plot, box plot | Pie |
| Part-to-whole | Stacked bar, treemap | 3D pie, donut |
| Correlation | Scatter plot | Bubble (unless 3rd variable) |
| KPI vs target | Bullet graph | Gauge, dial, speedometer |
| Geographic | Choropleth, proportional symbol | 3D globe |
| Current status | Indicator + value | Animation |

Pick the simplest display that answers the question. If a table works, use a table.

### 3. Who is looking at this?

| Audience | Precision | Context | Density |
|----------|-----------|---------|---------|
| Executive | Trends, not decimals ($1.2M) | vs target, vs prior period | Low — 5 metrics max |
| Analyst | Full precision ($1,234,567) | Drill-down, filter, compare | High — coordinated views |
| Operations | Current state, real-time | Alerts, thresholds | Medium — status indicators |

---

## Building the Visualization

### Step 1: Data Structure First

Define the data shape before touching SVG. The data drives everything.

```javascript
// Define your data contract
const data = [
  { id: "q1", date: new Date("2024-01"), value: 42, category: "A" }
];

// Derive domains from data, never hardcode
const x = d3.scaleTime()
  .domain(d3.extent(data, d => d.date))
  .range([0, width]);
```

- Domains from data (`d3.extent`, `d3.max`), not magic numbers
- Key field present for identity (`.data(data, d => d.id)`)
- Correct scale type for data type (time, linear, band, ordinal, sqrt)
- `scaleSqrt()` for area encodings — never `scaleLinear()` on radius

### Step 2: Margin Convention

Every chart starts here:

```javascript
const margin = { top: 20, right: 30, bottom: 40, left: 50 };
const width = containerWidth - margin.left - margin.right;
const height = containerHeight - margin.top - margin.bottom;

const svg = d3.select(el).append("svg")
    .attr("viewBox", `0 0 ${containerWidth} ${containerHeight}`)
  .append("g")
    .attr("transform", `translate(${margin.left},${margin.top})`);
```

- `viewBox` for responsive sizing, not fixed `width`/`height` attributes
- Scales use inner `width`/`height`
- No positioning math elsewhere — margins handle it once

### Step 3: Data Joins

Binddata to elements. Handle all three states.

```javascript
svg.selectAll("rect")
  .data(data, d => d.id)       // Key function — always
  .join(
    enter => enter.append("rect")
      .attr("x", d => x(d.date))
      .attr("height", 0)
      .call(enter => enter.transition()
        .attr("height", d => height - y(d.value))),
    update => update
      .call(update => update.transition()
        .attr("x", d => x(d.date))
        .attr("height", d => height - y(d.value))),
    exit => exit
      .call(exit => exit.transition()
        .attr("height", 0)
        .remove())
  );
```

- Key function on every `.data()` call when data changes
- Enter/update/exit handled explicitly — no `selectAll("*").remove()` redraws
- Transitions show what changed, not decoration

### Step 4: Graphical Integrity (Tufte)

**Lie Factor must be 0.95–1.05.** Check these:

| Rule | Violation | Fix |
|------|-----------|-----|
| Bar charts start at zero | Truncated Y-axis exaggerates | `domain([0, max])` |
| Area = sqrt encoding | Linear radius on bubbles → 4x visual error | `d3.scaleSqrt()` |
| Consistent scales | Small multiples with different Y ranges | Shared domain across panels |
| No dual Y-axes | Misleading correlation | Two charts or normalize |

**Data-ink ratio > 70%.** Remove:

| Remove | Replace with |
|--------|-------------|
| Heavy gridlines | Light gray (#e5e5e5) at 0.5px, or none |
| Axis domain lines | Just ticks, or nothing |
| Borders/boxes | White space |
| Legends | Direct labels on data |
| Background colors | White/transparent |
| 3D effects | Nothing (2D always) |

**Direct labeling over legends.** Put the label at the data point:

```javascript
// Label on the line, not in a box somewhere
const lastPoint = data[data.length - 1];
svg.append("text")
  .attr("x", x(lastPoint.date) + 4)
  .attr("y", y(lastPoint.value))
  .attr("dy", "0.35em")
  .text(lastPoint.category);
```

### Step 5: Color Discipline (Few)

**Default: grayscale.** Color is a scarce resource.

```javascript
// Base palette: grays
const base = "#333";      // text, primary data
const muted = "#999";     // secondary, axes
const light = "#e5e5e5";  // gridlines, borders

// Color ONLY for meaning
const alert = "#d32f2f";  // bad / below target
const success = "#388e3c"; // good / above target
const highlight = "#1565c0"; // selected / focus
```

- When everything is colorful, nothing stands out
- Always pair color with a value — never traffic lights alone
- Colorblind safe: add shape or text, don't rely on red/green distinction
- If you need categorical colors, use 5 or fewer with maximum perceptual distance

### Step 6: Typography and Craft

Charts are read, not just seen. Typography matters.

- **Axis labels**: Short, no abbreviations the audience wouldn't know. Units in the axis title, not on every tick.
- **Title**: States the insight, not the data. "Revenue grew 23% in Q4" not "Revenue by Quarter"
- **Numbers**: Format for the audience. `d3.format("$.2s")` for executives (→ $1.2M), `d3.format("$,.0f")` for analysts (→ $1,234,568).
- **Font**: Use the application's typeface. Don't introduce a new one for charts.

```javascript
// Tick formatting
xAxis.tickFormat(d3.timeFormat("%b")); // "Jan", "Feb"
yAxis.tickFormat(d3.format("$.2s"));   // "$1.2M"
yAxis.ticks(5);                        // Don't crowd
```

### Step 7: Responsive and Accessible

- `viewBox` on SVG, no fixed dimensions
- ARIA: `role="img"` + `aria-label` on SVG container
- `<title>` and `<desc>` elements inside SVG
- Text alternatives for data conveyed only visually
- Keyboard focus indicators on interactive elements
- `prefers-reduced-motion` check before transitions
- `prefers-color-scheme` for dark mode support

```javascript
const prefersReducedMotion = window.matchMedia(
  "(prefers-reduced-motion: reduce)"
).matches;

const t = svg.transition()
  .duration(prefersReducedMotion ? 0 : 750);
```

### Step 8: Reusable Chart Pattern

If this chart will be used more than once, extract it:

```javascript
function bulletChart() {
  let width = 300;
  let height = 30;
  let ranges = [0.5, 0.75, 1.0];

  function chart(selection) {
    selection.each(function(d) {
      // Build chart using width, height, ranges, d
    });
  }

  chart.width = function(v) {
    return arguments.length ? (width = v, chart) : width;
  };

  chart.height = function(v) {
    return arguments.length ? (height = v, chart) : height;
  };

  chart.ranges = function(v) {
    return arguments.length ? (ranges = v, chart) : ranges;
  };

  return chart;
}

// Usage
d3.selectAll(".bullet").datum(d => d).call(bulletChart().width(400));
```

Closure pattern, not classes. Getter-setter methods. Callable via `selection.call()`.

---

## Dashboard Layout (Few)

If building a dashboard, not a single chart:

- **Single screen.** If it scrolls, it's a report. Prioritize ruthlessly.
- **Top-left = most important.** Scan order: top-left → top-right → bottom-left → bottom-right.
- **Group related metrics.** Proximity implies relationship.
- **Bullet graphs replace gauges.** Always. 10x more data density.
- **Sparklines for trends.** Inline, no axes, just the shape.
- **Context on every number.** vs target, vs prior period, or qualitative range. A number alone is meaningless.

---

## Anti-Patterns

| Anti-Pattern | Why | Do Instead |
|-------------|-----|-----------|
| Pie charts | Humans are bad at comparing angles | Horizontal bar, sorted |
| Gauges/dials | One number, massive footprint | Bullet graph |
| 3D anything | Distorts perception, always | 2D |
| Rainbow color scales | No perceptual ordering | Sequential single-hue or diverging |
| Dual Y-axes | Implies false correlation | Two charts or normalize |
| Full redraws on update | Destroys transitions, wastes DOM | Data joins with enter/update/exit |
| Index-based data joins | Elements track position, not data | Key functions: `.data(d, d => d.id)` |
| Decorative animation | Slows comprehension | Transition only on data change |
| Legend for <8 series | Forces cognitive round-trip | Direct labels |
| Area encoding with linear scale | 4x visual exaggeration | `scaleSqrt()` |

---

## Checklist Before Shipping

**Integrity**
- [ ] Lie Factor 0.95–1.05 (bars at zero, sqrt for area, consistent scales)
- [ ] No dual Y-axes
- [ ] No 3D, no pie charts

**Clarity**
- [ ] Title states the insight, not the data type
- [ ] Direct labels, not legends (where feasible)
- [ ] Numbers formatted for the audience
- [ ] Color used for meaning, not decoration

**Craft**
- [ ] Margin convention applied
- [ ] viewBox for responsive sizing
- [ ] ARIA labels and text alternatives
- [ ] `prefers-reduced-motion` respected
- [ ] Data joins with key functions (no full redraws)

**Dashboard (if applicable)**
- [ ] Single screen, no scroll
- [ ] Most important metric top-left
- [ ] Context on every number (vs target, vs prior)
- [ ] Bullet graphs, not gauges
