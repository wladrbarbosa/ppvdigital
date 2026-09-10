#!/usr/bin/env python3
"""
defringe.py - Reusable image defringing and alpha unmatting utility.

Removes white (or colored) fringes, halos, and background leakage from
cutout images and transparent PNGs by recovering true foreground colors
and anti-aliasing alpha via mathematical unmatting.
"""

import argparse
import sys
from collections import deque
import numpy as np
from PIL import Image


def parse_color(color_str):
    color_str = color_str.strip().lstrip('#')
    if ',' in color_str:
        parts = [int(p.strip()) for p in color_str.split(',')]
        if len(parts) != 3:
            raise ValueError("RGB color must have 3 comma-separated components")
        return [float(p) for p in parts]
    elif len(color_str) == 6:
        return [float(int(color_str[i:i+2], 16)) for i in (0, 2, 4)]
    else:
        raise ValueError(f"Invalid color format: {color_str}. Use #RRGGBB or R,G,B")


def defringe_image(
    input_path,
    output_path=None,
    bg_color=(255.0, 255.0, 255.0),
    clear_leakage=True,
    max_search_dist=8,
    cutoff_haze=0.12,
):
    """
    Cleans white/colored halos and anti-aliasing fringes from transparent PNGs.
    """
    if output_path is None:
        output_path = input_path

    im = Image.open(input_path).convert('RGBA')
    arr = np.array(im, dtype=np.float32)
    h, w = arr.shape[:2]

    rgb = arr[:, :, :3]
    alpha = arr[:, :, 3]
    W = np.array(bg_color, dtype=np.float32)

    # 1. Clear isolated background leakage if enabled
    if clear_leakage and np.all(W >= 240):
        # Pixels very close to white with minimal saturation that were kept opaque
        color_dist_to_bg = np.linalg.norm(rgb - W, axis=2)
        saturation = np.max(rgb, axis=2) - np.min(rgb, axis=2)
        is_leak = (alpha > 0) & (color_dist_to_bg < 35.0) & (saturation < 30.0)
        leak_count = int(np.sum(is_leak))
        if leak_count > 0:
            print(f"[defringe] Cleared {leak_count} background leakage pixels.")
            alpha[is_leak] = 0.0

    is_trans = (alpha == 0)
    is_opaque = (alpha > 128)

    # 2. Compute distance to nearest transparent pixel
    dist = np.full((h, w), 999, dtype=np.int32)
    q = deque()
    for y in range(h):
        for x in range(w):
            if is_trans[y, x]:
                dist[y, x] = 0
                q.append((y, x))

    while q:
        y, x = q.popleft()
        d = dist[y, x]
        if d >= max_search_dist:
            continue
        for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and dist[ny, nx] > d + 1:
                dist[ny, nx] = d + 1
                q.append((ny, nx))

    # Deep interior: opaque pixels far enough from boundary (distance >= 3)
    deep_interior = is_opaque & (dist >= 3)

    # 3. Find nearest deep interior pixel for clean foreground color F
    nearest_y = np.full((h, w), -1, dtype=np.int32)
    nearest_x = np.full((h, w), -1, dtype=np.int32)
    interior_dist = np.full((h, w), 999, dtype=np.int32)

    q_int = deque()
    deep_ys, deep_xs = np.where(deep_interior)
    for y, x in zip(deep_ys, deep_xs):
        nearest_y[y, x] = y
        nearest_x[y, x] = x
        interior_dist[y, x] = 0
        q_int.append((y, x))

    while q_int:
        y, x = q_int.popleft()
        d = interior_dist[y, x]
        if d >= max_search_dist + 4:
            continue
        ny_orig = nearest_y[y, x]
        nx_orig = nearest_x[y, x]
        for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and is_opaque[ny, nx] and interior_dist[ny, nx] > d + 1:
                interior_dist[ny, nx] = d + 1
                nearest_y[ny, nx] = ny_orig
                nearest_x[ny, nx] = nx_orig
                q_int.append((ny, nx))

    # Construct foreground estimate F
    F = rgb.copy()
    edge_mask = is_opaque & (dist <= 3)
    valid_nearest = edge_mask & (nearest_y >= 0)
    ny_val = nearest_y[valid_nearest]
    nx_val = nearest_x[valid_nearest]
    F[valid_nearest] = rgb[ny_val, nx_val]

    # 4. Mathematical Unmatting against background W:
    # C = alpha * F + (1 - alpha) * W  =>  (W - C) = alpha * (W - F)
    diff_W_C = W - rgb
    diff_W_F = W - F

    dot_num = np.sum(diff_W_C * diff_W_F, axis=2)
    dot_den = np.sum(diff_W_F * diff_W_F, axis=2) + 1e-6
    calc_alpha = np.clip(dot_num / dot_den, 0.0, 1.0)

    new_rgb = rgb.copy()
    new_alpha = alpha.copy()

    # Distance 1 (outermost edge pixels)
    d1 = is_opaque & (dist == 1)
    scaled_alpha_d1 = np.clip((calc_alpha[d1] - cutoff_haze) / (1.0 - cutoff_haze), 0.0, 1.0)
    new_alpha[d1] = scaled_alpha_d1 * 255.0
    new_rgb[d1] = F[d1]

    # Distance 2 (sub-boundary pixels)
    d2 = is_opaque & (dist == 2)
    d2_contam = d2 & (calc_alpha < 0.85)
    scaled_alpha_d2 = np.clip((calc_alpha[d2_contam] - 0.08) / (1.0 - 0.08), 0.0, 1.0)
    new_alpha[d2_contam] = scaled_alpha_d2 * 255.0
    new_rgb[d2_contam] = F[d2_contam]

    # Distance 2 mild (mild background wash-out, restore full foreground color)
    d2_mild = d2 & (calc_alpha >= 0.85) & (calc_alpha < 0.98)
    new_rgb[d2_mild] = F[d2_mild]

    # Distance 3 (check deep edge)
    d3 = is_opaque & (dist == 3) & (calc_alpha < 0.85)
    new_rgb[d3] = F[d3]

    # Ensure transparent stays 0
    new_alpha[is_trans] = 0.0

    result = np.dstack([
        np.clip(new_rgb, 0, 255).astype(np.uint8),
        np.clip(new_alpha, 0, 255).astype(np.uint8),
    ])

    out_im = Image.fromarray(result, 'RGBA')
    out_im.save(output_path)
    print(f"[defringe] Successfully saved defringed image to: {output_path}")


def main():
    parser = argparse.ArgumentParser(
        description="Remove white/colored halos and fringes from transparent PNGs."
    )
    parser.add_argument("input", help="Path to input image (PNG)")
    parser.add_argument("output", nargs="?", default=None, help="Path to output image (defaults to overwrite input)")
    parser.add_argument(
        "--bg-color",
        default="255,255,255",
        help="Background color contaminated in fringes (hex '#FFFFFF' or 'R,G,B', default: 255,255,255)",
    )
    parser.add_argument(
        "--no-leak-clean",
        action="store_true",
        help="Disable clearing trapped pure background leakage pixels",
    )
    parser.add_argument(
        "--haze-cutoff",
        type=float,
        default=0.12,
        help="Alpha threshold to drop background noise (default: 0.12)",
    )

    args = parser.parse_args()
    bg = parse_color(args.bg_color)
    defringe_image(
        args.input,
        output_path=args.output,
        bg_color=bg,
        clear_leakage=not args.no_leak_clean,
        cutoff_haze=args.haze_cutoff,
    )


if __name__ == "__main__":
    main()
