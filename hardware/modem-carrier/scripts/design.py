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
s.part("C11", "Device:C", "100nF MODULE VBAT LOCAL", {"1": "MODEM_VBAT_3V8", "2": "GND"}, block=block)
s.part("C12", "Device:C", "1uF MODULE VBAT LOCAL", {"1": "MODEM_VBAT_3V8", "2": "GND"}, block=block)
s.part("C13", "Device:C", "33pF MODULE VBAT LOCAL", {"1": "MODEM_VBAT_3V8", "2": "GND"}, block=block)
s.part("C14", "Device:C", "10pF MODULE VBAT LOCAL", {"1": "MODEM_VBAT_3V8", "2": "GND"}, block=block)
s.part("D1", "Device:D_TVS", "ESDBW5V0A1 5V VRWM TVS", {"1": "MODEM_VBAT_3V8", "2": "GND"}, block=block)

# Output connector is a test / future module VBAT connection, not the modem LGA footprint.
s.part("J2", "Connector_Generic:Conn_01x02", "3V8 MODEM VBAT OUTPUT", {
    "1": "MODEM_VBAT_3V8", "2": "GND"
}, block=block)

s.flag("MODEM_5V_IN", "MODEM_5V_SW", "MODEM_VBAT_3V8", "GND")
# Controller-to-modem logic interface. J2 pin 6 remains intentionally NC because
# SIMCom's family guide conflicts on A7670 pad 66 (GND vs STATUS).
block2 = "MODEM LOGIC INTERFACE"
s.note(block2, "J2 supplies only signals and GND; the carrier generates its own 3.3V translator rail from MODEM_5V_SW. The module supplies the 1.8V translator rail from VDD_1V8 (50mA max).")
s.note(block2, "PWRKEY and RESET are active-low at the modem. The NPN stages invert controller GPIO levels: J2 GPIO HIGH pulls the module pin LOW. Use the SIMCom pulse timings; never assert both together.")
s.note(block2, "J4 is a logical placeholder for the module pins, not a physical connector. Replace it with the complete, manufacturer-confirmed A7670E-LASA LGA symbol before PCB layout.")

# Carrier-side female socket mates to the controller's J2 male 1x06 header.
s.part("J3", "Connector_Generic:Conn_01x06", "CONTROLLER J2 SIGNAL INPUT", {
    "1": "GND",
    "2": "MCU_TO_MODEM_TX",
    "3": "MODEM_TO_MCU_RX",
    "4": "MODEM_PWRKEY",
    "5": "MODEM_RESET",
    "6": None,
}, block=block2)

# Logical A7670E signal placeholder; not a physical connector or final module symbol.
s.part("J4", "Connector_Generic:Conn_01x06", "A7670E LGA LOGIC PORT — PLACEHOLDER ONLY", {
    "1": "MODEM_VDD_1V8",
    "2": "MODEM_TXD",
    "3": "MODEM_RXD",
    "4": "MODEM_PWRKEY_N",
    "5": "MODEM_RESET_N",
    "6": "GND",
}, block=block2)

# Local 3.3V reference rail for the A-side of the translator and OE.
s.part("U3", "Regulator_Linear:AP2112K-3.3", "AP2112K-3.3TRG1", {
    "1": "MODEM_5V_SW",
    "2": "GND",
    "3": "MODEM_5V_SW",
    "4": None,
    "5": "CTRL_3V3",
}, block=block2)
s.part("C15", "Device:C", "1uF LDO INPUT", {"1": "MODEM_5V_SW", "2": "GND"}, block=block2)
s.part("C16", "Device:C", "1uF LDO OUTPUT", {"1": "CTRL_3V3", "2": "GND"}, block=block2)
s.part("C17", "Device:C", "100nF TXU VCCA BYPASS", {"1": "CTRL_3V3", "2": "GND"}, block=block2)
s.part("C18", "Device:C", "100nF TXU VCCB BYPASS", {"1": "MODEM_VDD_1V8", "2": "GND"}, block=block2)

# TI TXU0202: fixed channel A1 -> B1Y and B2 -> A2Y.
s.part("U2", "parts:TXU0202QDTTRQ1", "TXU0202DCU", {
    "1": "MODEM_TXD",       # B2 input, module TXD
    "2": "GND",
    "3": "CTRL_3V3",        # VCCA
    "4": "MODEM_TO_MCU_RX", # A2Y output to ESP32 RX
    "5": "MCU_TO_MODEM_TX", # A1 input from ESP32 TX
    "6": "CTRL_3V3",        # OE active high
    "7": "MODEM_VDD_1V8",   # VCCB from module VDD_1V8
    "8": "MODEM_RXD",       # B1Y output to module RXD
}, block=block2)

# PWRKEY open-collector stage: GPIO38 high turns Q1 on and pulls modem PWRKEY low.
s.part("R5", "Device:R", "4.7k PWRKEY BASE", {"1": "MODEM_PWRKEY", "2": "PWRKEY_BASE"}, block=block2)
s.part("R6", "Device:R", "47k PWRKEY BASE PULLDOWN", {"1": "PWRKEY_BASE", "2": "GND"}, block=block2)
s.part("Q1", "Transistor_BJT:MMBT3904", "MMBT3904 PWRKEY", {
    "1": "PWRKEY_BASE", "2": "GND", "3": "PWRKEY_COLLECTOR"
}, block=block2)
s.part("R7", "Device:R", "1k PWRKEY COLLECTOR SERIES", {"1": "PWRKEY_COLLECTOR", "2": "MODEM_PWRKEY_N"}, block=block2)
s.part("D2", "Device:D_TVS", "ESDBW5V0A1 PWRKEY TVS", {"1": "MODEM_PWRKEY_N", "2": "GND"}, block=block2)

# RESET open-collector stage: GPIO39 high pulls modem RESET low; emergency use only.
s.part("R8", "Device:R", "4.7k RESET BASE", {"1": "MODEM_RESET", "2": "RESET_BASE"}, block=block2)
s.part("R9", "Device:R", "47k RESET BASE PULLDOWN", {"1": "RESET_BASE", "2": "GND"}, block=block2)
s.part("Q2", "Transistor_BJT:MMBT3904", "MMBT3904 RESET", {
    "1": "RESET_BASE", "2": "GND", "3": "RESET_COLLECTOR"
}, block=block2)
s.part("R10", "Device:R", "1k RESET COLLECTOR SERIES", {"1": "RESET_COLLECTOR", "2": "MODEM_RESET_N"}, block=block2)
s.part("D3", "Device:D_TVS", "ESDBW5V0A1 RESET TVS", {"1": "MODEM_RESET_N", "2": "GND"}, block=block2)

# This flag stands in for the A7670 module's VDD_1V8 power-output pin until the
# module symbol is added after SIMCom resolves the exact LASA pad map.
s.flag("MODEM_VDD_1V8", "MODEM_TXD")

s.write("board.kicad_sch", overwrite=True)