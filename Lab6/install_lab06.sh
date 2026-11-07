#!/bin/bash
# Copies the Lab06 Verilog files from the SD card's boot partition into your Lab06 folder.
# Run on the Pi:  bash /boot/firmware/Lab06/install_lab06.sh
set -e
SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/ECEN_350_Labs/ECEN350_Labs/Lab06"
mkdir -p "$DEST"
BACKUP="$DEST/starter_backup_$(date +%Y%m%d_%H%M%S)"
for f in SignExtender.v SignExtender_tb.v ALU.v ALU_tb.v NextPClogic.v NextPClogic_tb.v; do
    if [ -f "$DEST/$f" ]; then
        mkdir -p "$BACKUP"
        cp "$DEST/$f" "$BACKUP/"
    fi
    tr -d '\r' < "$SRC/$f" > "$DEST/$f"
    echo "copied $f"
done
cp "$SRC/ECEN350_Lab06_Guide.pdf" "$DEST/" 2>/dev/null || true
[ -d "$BACKUP" ] && echo "old versions saved in $BACKUP"
echo
echo "Done. Now run:"
echo "  cd $DEST"
echo "  iverilog -o se SignExtender.v SignExtender_tb.v && vvp se"
echo "  iverilog -o alu ALU.v ALU_tb.v && vvp alu"
echo "  iverilog -o npc NextPClogic.v NextPClogic_tb.v && vvp npc"
