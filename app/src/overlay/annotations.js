import * as THREE from 'three'
import { mdiPath } from '../icons.js'

const SVGNS = 'http://www.w3.org/2000/svg'
// Sizes are +50% over the original blueprint scale (larger, more legible chips).
const FONT = 22, CHIP_H = 40, PAD = 14, ICON = 26, GAP = 11, MIN_GAP = 54
// Step-number badge: the container stack builds bottom-first, but a Dockerfile
// reads top-down, so each chip carries its 1-based command sequence number to
// make the true order explicit. The badge floats OUTSIDE the chip, just past its
// right edge, as its own element (BADGE_GAP separates it from the chip).
const BADGE_R = 13, NUM_FONT = 17, BADGE_GAP = 10

// Blueprint annotations: each visible layer slab gets a labelled chip parked in
// a right-hand gutter (never over the busy 3D), joined to the slab by a leader
// line. Chips are de-collided vertically so stacked layers don't overlap.
export function createAnnotations({ svgRoot, slabs, camera, renderer }) {
  const groups = slabs.map((s, i) => {
    const g = document.createElementNS(SVGNS, 'g')

    const line = document.createElementNS(SVGNS, 'line')
    line.setAttribute('stroke', '#38f5c9')
    line.setAttribute('stroke-width', '1.6')
    line.setAttribute('stroke-dasharray', '4 3')
    line.setAttribute('opacity', '0.8')

    const rect = document.createElementNS(SVGNS, 'rect')
    rect.setAttribute('height', CHIP_H)
    rect.setAttribute('rx', '6')
    rect.setAttribute('fill', '#050a12')
    rect.setAttribute('fill-opacity', '0.82')
    rect.setAttribute('stroke', '#1c6b78')
    rect.setAttribute('stroke-width', '1')

    // Step-number badge (slab index in Dockerfile order, 1-based).
    const badge = document.createElementNS(SVGNS, 'circle')
    badge.setAttribute('r', BADGE_R)
    badge.setAttribute('fill', '#38f5c9')
    const num = document.createElementNS(SVGNS, 'text')
    num.setAttribute('fill', '#050a12')
    num.setAttribute('font-family', 'ui-monospace, monospace')
    num.setAttribute('font-size', NUM_FONT)
    num.setAttribute('font-weight', '700')
    num.setAttribute('text-anchor', 'middle')
    num.setAttribute('dominant-baseline', 'central')
    num.textContent = `${i + 1}`

    const icon = document.createElementNS(SVGNS, 'svg')
    icon.setAttribute('width', ICON)
    icon.setAttribute('height', ICON)
    icon.setAttribute('viewBox', '0 0 24 24')
    const ipath = document.createElementNS(SVGNS, 'path')
    ipath.setAttribute('fill', '#38f5c9')
    ipath.setAttribute('d', mdiPath(s.data.icon))
    icon.append(ipath)

    const text = document.createElementNS(SVGNS, 'text')
    text.setAttribute('fill', '#d6fff5')
    text.setAttribute('font-family', 'ui-monospace, monospace')
    text.setAttribute('font-size', FONT)
    text.setAttribute('dominant-baseline', 'middle')
    text.textContent = `${s.data.instruction} ${s.data.args}`

    g.append(line, rect, badge, num, icon, text)
    svgRoot.append(g)

    const tw = text.getComputedTextLength() || text.textContent.length * FONT * 0.6
    const chipW = PAD + ICON + GAP + tw + PAD
    return { s, g, line, rect, badge, num, icon, text, chipW, sx: 0, sy: 0, cy: 0 }
  })

  const v = new THREE.Vector3()
  function update() {
    const w = renderer.domElement.clientWidth
    const h = renderer.domElement.clientHeight
    const maxChipW = Math.max(...groups.map((o) => o.chipW))
    // reserve room on the right for the floating step badge past the widest chip
    const gutterX = w - maxChipW - (BADGE_GAP + 2 * BADGE_R) - 28

    // Which labels are visible, and where their slab projects on screen.
    const vis = []
    for (const o of groups) {
      const on = o.s.labelOn.v > 0.5
      o.g.style.display = on ? '' : 'none'
      if (!on) continue
      o.s.mesh.getWorldPosition(v).project(camera)
      o.sx = (v.x * 0.5 + 0.5) * w
      o.sy = (-v.y * 0.5 + 0.5) * h
      vis.push(o)
    }

    // De-collide: sort by projected y, enforce a minimum vertical gap.
    vis.sort((a, b) => a.sy - b.sy)
    let prevY = -Infinity
    for (const o of vis) {
      o.cy = o.sy < prevY + MIN_GAP ? prevY + MIN_GAP : o.sy
      prevY = o.cy
    }

    for (const o of vis) {
      const cy = o.cy
      o.rect.setAttribute('x', gutterX)
      o.rect.setAttribute('y', cy - CHIP_H / 2)
      o.rect.setAttribute('width', o.chipW)
      o.icon.setAttribute('x', gutterX + PAD)
      o.icon.setAttribute('y', cy - ICON / 2)
      o.text.setAttribute('x', gutterX + PAD + ICON + GAP)
      o.text.setAttribute('y', cy)
      // step badge floats just past this chip's own right edge
      const badgeCx = gutterX + o.chipW + BADGE_GAP + BADGE_R
      o.badge.setAttribute('cx', badgeCx)
      o.badge.setAttribute('cy', cy)
      o.num.setAttribute('x', badgeCx)
      o.num.setAttribute('y', cy)
      o.line.setAttribute('x1', o.sx)
      o.line.setAttribute('y1', o.sy)
      o.line.setAttribute('x2', gutterX - 4)
      o.line.setAttribute('y2', cy)
    }
  }

  return { update }
}
