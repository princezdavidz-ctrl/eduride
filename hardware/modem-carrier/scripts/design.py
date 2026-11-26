from pcbkit.schematic import Schematic

s = Schematic(
    "Edu Ride A7670E LTE Carrier",
    title="Edu Ride LTE Carrier — Preliminary 3.8 V Modem Power Stage",
    rev="A0-PROTOTYPE",
    company="Project Edu Ride",
    project_dir=".",
)
block = "3.8V MODEM POWER STAGE"
s.note(block, "Preliminary 5 V to 3.8 V / 2.8 A conservative modem rail. Values and layout remain subject to datasheet, stability, thermal and bench verification.")

# External power from controller J14: pin 1 = protected +5 V, pin 2 = GND.
s.part("J1", "Connector_Generic:Conn_01x02", "J14 CARRIER POWER INPUT", {
    "1": "MODEM_5V_IN", "2": "GND"
}, block=block)

# Removable zero-ohm/current-measurement link. Replace only after current and fuse strategy review.
s.part("R1", "Device:R", "0R INPUT LINK / CURRENT MEASUREMENT", {
    "1": "MODEM_5V_IN", "2": "MODEM_5V_SW"
}, block=block, fields={"Datasheet": ""})

# LT8640EUDC#TRPBF: official ADI pin numbering, corrected electrical pin types.
s.part("U1", "parts:LT8640EUDC#TRPBF", "LT8640EUDC#TRPBF", {
    "1": "MODEM_VBAT_3V8",   # BIAS
    "2": "INTVCC",
    "3": "BST",
    "4": "MODEM_5V_SW",     # VIN1
    "6": "GND", "7": "GND",
    "8": "SW_MODEM", "9": "SW_MODEM",
    "10": "GND", "11": "GND",
    "13": "MODEM_5V_SW",    # VIN2
    "14": "MODEM_5V_SW",    # EN/UV
    "15": "RT_MODEM",
    "16": "SS_MODEM",
    "17": "GND",            # SYNC/MODE: Burst Mode for first prototype
    "18": "GND",
    "19": None,              # PG intentionally not used in this prototype
    "20": "FB_MODEM",
    "21": "SW_MODEM", "22": "SW_MODEM",
}, block=block)

# Switching and timing network.
s.part("L1", "Device:L", "2.7uH HPPC10024-2R7M-Q8", {
    "1": "SW_MODEM", "2": "MODEM_VBAT_3V8"
}, block=block)
s.part("C1", "Device:C", "100nF BST-SW", {"1": "BST", "2": "SW_MODEM"}, block=block)
s.part("C2", "Device:C", "1uF INTVCC BYPASS", {"1": "INTVCC", "2": "GND"}, block=block)
s.part("C3", "Device:C", "10nF SOFT START", {"1": "SS_MODEM", "2": "GND"}, block=block)
s.part("R2", "Device:R", "41.2k RT / 1MHz", {"1": "RT_MODEM", "2": "GND"}, block=block)

# Feedback divider and feed-forward capacitor: 0.970 V nominal reference gives about 3.798 V.
s.part("R3", "Device:R", "1.000M FB TOP", {"1": "MODEM_VBAT_3V8", "2": "FB_MODEM"}, block=block)
s.part("R4", "Device:R", "343k FB BOTTOM", {"1": "FB_MODEM", "2": "GND"}, block=block)
s.part("C4", "Device:C", "4.7pF FEED-FORWARD", {"1": "MODEM_VBAT_3V8", "2": "FB_MODEM"}, block=block)

# Input bypassing at the two VIN pins and common input node.
s.part("C5", "Device:C", "4.7uF VIN BULK CERAMIC", {"1": "MODEM_5V_SW", "2": "GND"}, block=block)
s.part("C6", "Device:C", "1uF VIN1 LOCAL", {"1": "MODEM_5V_SW", "2": "GND"}, block=block)
s.part("C7", "Device:C", "1uF VIN2 LOCAL", {"1": "MODEM_5V_SW", "2": "GND"}, block=block)

# Output bypassing: 47uF ceramic plus two 330uF polymer bulk capacitors.
s.part("C8", "Device:C", "47uF X7R OUTPUT CERAMIC", {"1": "MODEM_VBAT_3V8", "2": "GND"}, block=block)
s.part("C9", "Device:C_Polarized", "330uF 6.3V POLYMER", {"1": "MODEM_VBAT_3V8", "2": "GND"}, block=block)
s.part("C10", "Device:C_Polarized", "330uF 6.3V POLYMER", {"1": "MODEM_VBAT_3V8", "2": "GND"}, block=block)

# Output connector is a test / future module VBAT connection, not the modem LGA footprint.
s.part("J2", "Connector_Generic:Conn_01x02", "3V8 MODEM VBAT OUTPUT", {
    "1": "MODEM_VBAT_3V8", "2": "GND"
}, block=block)

s.flag("MODEM_5V_IN", "MODEM_5V_SW", "MODEM_VBAT_3V8", "GND")
s.write("board.kicad_sch", overwrite=True)