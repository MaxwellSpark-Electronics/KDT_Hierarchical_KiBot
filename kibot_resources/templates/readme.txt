![Logo](Logos/dummy_logo.png)

# ${BOARD_NAME}

[![CI Badge](${GIT_URL}/actions/workflows/ci.yaml/badge.svg?branch=)](${GIT_URL}/actions/workflows/ci.yaml)

![Main Render](Images/dummy_image.png)

***

![3D Top Angled](${png_3d_viewer_angled_top_outpath}) 
![3D Bottom Angled](${png_3d_viewer_angled_bottom_outpath})

***

## SPECIFICATIONS

![KiCad Version](https://img.shields.io/badge/KiCad-9.0-brightgreen.svg)
![Layers](https://img.shields.io/badge/Layers-2-informational.svg)

| Parameter | Value | 
| --- | --- |
| Dimensions | ${bb_w_mm} × ${bb_h_mm} mm |

***

## DIRECTORY STRUCTURE

    .
    │
    ├─ 3D                # PCB 3D Models 
    │
    ├─ Calculations       # Misc calculations
    ├─ HTML               # HTML files for generated webpage
    ├─ Images             # Pictures and renders
    │
    ├─ kibot_resources    # External resources for KiBot
    │  ├─ colors          # Color theme for KiCad
    │  ├─ fonts           # Fonts used in the project
    │  ├─ scripts         # External scripts used with KiBot
    │  └─ templates       # Templates for KiBot generated reports
    │
    ├─ kibot_yaml         # KiBot YAML config files
    ├─ KiRI               # KiRI (PCB diff viewer) files
    │
    ├─ lib                # KiCad footprint and symbol libraries
    │  ├─ 3d_models       # Component 3D models
    │  ├─ lib_fp          # Footprint libraries
    │  └─ lib_sym         # Symbol libraries
    │
    ├─ Logos              # Logos
    │
    ├─ Manufacturing      # Assembly and fabrication documents
    │  ├─ Assembly        # Assembly documents (BoM, pos, notes)
    │  │
    │  └─ Fabrication     # Fabrication documents (ZIP, notes)
    │     ├─ Drill Tables # CSV drill tables
    │     └─ Gerbers      # Gerbers
    │
    ├─ packages3D         # Component 3D models
    │
    ├─ Report             # Reports for ERC/DRC
    ├─ Schematic          # PDF of schematic
    ├─ Templates          # Title block templates
    ├─ Testing
    │  └─ Testpoints      # Testpoints tables      
    │
    └─ Variants           # Outputs for assembly variants
