---
name: diy-workflow
description: Develop firmware, CAD models, PCB designs, and print exports in this DIY flake project. Use when editing Arduino or PlatformIO projects, FreeCAD or OpenSCAD models, KiCad designs, or slicer profiles here.
---

# DIY project workflow

Read the project README for available shells and host setup. Enter the matching
shell from the project root; mix features in `nix/profiles.nix` when a task spans
firmware and mechanical or PCB design. Keep native sources in version control
and generated outputs under `build/` or `exports/`.

## Firmware

Identify the board, FQBN or PlatformIO board ID, and existing build configuration
before choosing a toolchain. Pin Arduino cores/libraries in a sketch build profile
or PlatformIO platforms/libraries in `platformio.ini`; the Nix lock pins the host
CLI, not packages that the CLI downloads. Compile before uploading. Select the
actual port explicitly, preferring `/dev/serial/by-id` on Linux; do not assume the
first attached board is the target. Shell entry never flashes devices.

## CAD and PCB

Record units, mechanical interfaces, tolerances and board constraints before
changing dimensions. Preserve editable `.FCStd`, `.scad`, and KiCad project files;
use STL, STEP and Gerber only as exports. Inspect exported geometry as well as
successful command exits. On KiCad changes, run the installed version's ERC/DRC
and report violations or explicit waivers before creating fabrication outputs.

## Printing

Use the target printer, nozzle, material and calibrated profile for slicing.
Record those settings with the native project or saved slicer configuration.
Inspect orientation, supports and toolpaths; an STL export alone does not verify
printability. Produce files for review without automatically starting a printer.

## Validation evidence

State which compiler checks, geometry exports, ERC/DRC or slicing checks ran.
Distinguish software validation from physical fit, electrical measurements, and
on-device behavior that require hardware. Keep existing authorization for uploads
or fabrication scoped to the identified device and artifact.
