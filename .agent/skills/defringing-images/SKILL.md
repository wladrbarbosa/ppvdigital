---
name: defringing-images
description: Use when transparent images, PNGs, logos, or icons have white halos, fringes, light outlines, or color bleeding along edges and cutouts when rendered on dark or colored backgrounds
---

# Defringing Images

## Overview

Image defringing eliminates background contamination (halos, fringes, and jagged borders) from transparent PNGs by recovering true foreground colors and anti-aliasing alpha via mathematical unmatting.

## When to Use

- Cutout images or logos show bright/white halos around text or shapes when placed over dark, colored, or gradient backgrounds.
- Background removal tools (e.g., thresholding, magic wand, flood-fill) left anti-aliased edge pixels contaminated with the original background color.
- Transparent assets have isolated background pixels trapped inside narrow notches, letter loops, or acute angles.
- High-contrast fringing is visible around icons or UI assets in dark mode.

**When NOT to use:**
- Vector graphics (SVG) — fix directly in SVG paths or strokes.
- Fully opaque images without transparency — use standard segmentation or background removal instead.
- Simple cropping or resizing tasks.

## Quick Reference

| Problem | Root Cause | Solution |
|---|---|---|
| White halo on dark background | Edges anti-aliased against white are kept fully opaque | Mathematical unmatting: $\alpha = \frac{(W - C)\cdot(W - F)}{\|W - F\|^2}$ |
| Trapped white pixels in notches | Thresholding missed off-white pixels inside acute angles | Detect low-saturation near-white pixels and set alpha to 0 |
| Washed out edge colors | Bleed from original background into edge pixels | Replace edge RGB with nearest deep interior foreground color $F$ |
| Rough/jagged edges | Hard binary alpha threshold ($0$ or $255$) | Rescale recovered alpha with smooth feathering |

## How Unmatting Works

When an asset is rasterized over a solid background $W$ (e.g. white `[255, 255, 255]`), edge pixels blend foreground color $F$ and background $W$ with coverage $\alpha$:

$$C = \alpha \cdot F + (1 - \alpha) \cdot W$$

Rearranging the linear blend allows exact recovery of the true alpha and pure foreground:

$$W - C = \alpha \cdot (W - F) \implies \alpha = \frac{(W - C) \cdot (W - F)}{\|W - F\|^2}$$

Once $\alpha$ is recovered:
1. Set the pixel's RGB to $F$ (pure foreground color, zero white contamination).
2. Set the pixel's Alpha to $\alpha \times 255$.
3. When rendered over any background (dark, light, or gradient), the edge blends cleanly with zero halo.

## Tool Execution

A standalone CLI script is bundled with this skill at `scripts/defringe.py`.

### Basic Usage

```bash
# Clean white fringes and overwrite the file in place:
python3 .agent/skills/defringing-images/scripts/defringe.py path/to/image.png

# Save output to a new file:
python3 .agent/skills/defringing-images/scripts/defringe.py input.png output.png

# Defringe against a specific background color (e.g. black or custom hex):
python3 .agent/skills/defringing-images/scripts/defringe.py input.png output.png --bg-color "#FFFFFF"
```

### Python Implementation

```python
import numpy as np
from PIL import Image
from collections import deque

def defringe(input_path: str, output_path: str, bg=(255.0, 255.0, 255.0)):
    im = Image.open(input_path).convert('RGBA')
    arr = np.array(im, dtype=np.float32)
    h, w = arr.shape[:2]
    rgb, alpha = arr[:, :, :3], arr[:, :, 3]
    W = np.array(bg, dtype=np.float32)

    # 1. Clear isolated background leakage (near-white, low saturation)
    if np.all(W >= 240):
        color_dist = np.linalg.norm(rgb - W, axis=2)
        sat = np.max(rgb, axis=2) - np.min(rgb, axis=2)
        alpha[(alpha > 0) & (color_dist < 35.0) & (sat < 30.0)] = 0.0

    # 2. Distance to transparent pixels via BFS
    is_trans = (alpha == 0)
    dist = np.full((h, w), 999, dtype=np.int32)
    q = deque([(y, x) for y in range(h) for x in range(w) if is_trans[y, x]])
    for y, x in q: dist[y, x] = 0

    while q:
        y, x = q.popleft()
        if dist[y, x] >= 8: continue
        for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and dist[ny, nx] > dist[y, x] + 1:
                dist[ny, nx] = dist[y, x] + 1
                q.append((ny, nx))

    # 3. Propagate clean deep interior color F (distance >= 3) to edge pixels
    deep = (alpha > 128) & (dist >= 3)
    nearest_y, nearest_x = np.full((h, w), -1, dtype=np.int32), np.full((h, w), -1, dtype=np.int32)
    q_deep = deque([(y, x) for y, x in zip(*np.where(deep))])
    for y, x in q_deep: nearest_y[y, x], nearest_x[y, x] = y, x

    while q_deep:
        y, x = q_deep.popleft()
        if dist[y, x] >= 12: continue
        for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and alpha[ny, nx] > 128 and nearest_y[ny, nx] < 0:
                nearest_y[ny, nx], nearest_x[ny, nx] = nearest_y[y, x], nearest_x[y, x]
                q_deep.append((ny, nx))

    # 4. Unmatte against background W
    edge = (alpha > 128) & (dist <= 3) & (nearest_y >= 0)
    F = rgb.copy()
    F[edge] = rgb[nearest_y[edge], nearest_x[edge]]

    diff_W_C, diff_W_F = W - rgb, W - F
    calc_alpha = np.clip(np.sum(diff_W_C * diff_W_F, axis=2) / (np.sum(diff_W_F**2, axis=2) + 1e-6), 0.0, 1.0)

    # Apply unmixed color & feathered alpha
    d1 = (alpha > 128) & (dist == 1)
    alpha[d1] = np.clip((calc_alpha[d1] - 0.12) / 0.88, 0.0, 1.0) * 255.0
    rgb[d1] = F[d1]

    d2 = (alpha > 128) & (dist == 2) & (calc_alpha < 0.85)
    alpha[d2] = np.clip((calc_alpha[d2] - 0.08) / 0.92, 0.0, 1.0) * 255.0
    rgb[d2] = F[d2]

    rgb[(alpha > 128) & (dist <= 3) & (calc_alpha >= 0.85)] = F[(alpha > 128) & (dist <= 3) & (calc_alpha >= 0.85)]
    alpha[is_trans] = 0.0

    out = Image.fromarray(np.dstack([np.clip(rgb, 0, 255).astype(np.uint8), np.clip(alpha, 0, 255).astype(np.uint8)]), 'RGBA')
    out.save(output_path)
```

## Common Mistakes

| Mistake | Why it Fails | Correct Approach |
|---|---|---|
| Applying simple erosion (`erode`) | Shrinks thin text strokes, rounds sharp corners, and degrades typography | Use unmatting to restore alpha coverage while keeping vector geometry intact |
| Binary thresholding ($0$ or $255$) | Creates harsh aliasing stairs and loses all smooth edge rendering | Preserve continuous alpha values $[0, 255]$ with smooth edge feathering |
| Leaving RGB unchanged with feathered alpha | The white background color remains blended into the edge RGB, producing a greyish haze | Always unmix and set edge RGB to pure foreground color $F$ |
| Ignoring trapped background pixels | Acute angles in letters (e.g., 'A', 'M', 'V') retain solid white patches | Filter low-saturation near-white pixels with high background proximity |
