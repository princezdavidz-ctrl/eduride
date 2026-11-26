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
s.note(block2, "PWRKEY and RESET are active-low at the modem. The NPN stages invert controller GPIO levels: J2 GPIO HIGH pulls the module pin LOW. PWRKEY low 50 ms powers on; low at least 2.5 s powers off; wait at least 2 s before power-on again. RESET low 2.0–2.5 s is emergency reset only. Never assert both together and do not add capacitors over 10 nF to either pin.")
s.note(block2, "Pad 66 STATUS/GND option: R25 (4.7k to the NPN status translator) and R28 (0R to GND) are mutually exclusive and both DNP by default. Populate only the option confirmed for the exact module revision; never populate both.")
s.note(block2, "J4 is a logical placeholder for the module pins, not a physical connector. Replace it with the complete, manufacturer-confirmed A7670E-LASA LGA symbol before PCB layout.")

# Carrier-side female socket mates to the controller's J2 male 1x06 header.
s.part("J3", "Connector_Generic:Conn_01x06", "CONTROLLER J2 SIGNAL INPUT", {
    "1": "GND",
    "2": "MCU_TO_MODEM_TX",
    "3": "MODEM_TO_MCU_RX",
    "4": "MODEM_PWRKEY",
    "5": "MODEM_RESET",
    "6": "MODEM_STATUS",
}, block=block2)

# Logical A7670E signal placeholder; not a physical connector or final module symbol.
s.part("J4", "Connector_Generic:Conn_01x07", "A7670E LGA LOGIC PORT — PLACEHOLDER ONLY", {
    "1": "MODEM_VDD_1V8",
    "2": "MODEM_TXD",
    "3": "MODEM_RXD",
    "4": "MODEM_PWRKEY_N",
    "5": "MODEM_RESET_N",
    "6": "GND",
    "7": "MODEM_STATUS_1V8",
}, block=block2)

# Local 3.3V reference rail for the A-side of the translator and OE.
s.part("U3", "Regulator_Linear:AP2112K-3.3", "AP2112K-3.3TRG1", {
    "1": "MODEM_5V_SW",
    "2": "GND",
    "3": "MODEM_5V_SW",
    "4": None,
    "5": "CARRIER_3V3",
}, block=block2)
s.part("C15", "Device:C", "1uF LDO INPUT", {"1": "MODEM_5V_SW", "2": "GND"}, block=block2)
s.part("C16", "Device:C", "1uF LDO OUTPUT", {"1": "CARRIER_3V3", "2": "GND"}, block=block2)
s.part("C17", "Device:C", "100nF TXU VCCA BYPASS", {"1": "CARRIER_3V3", "2": "GND"}, block=block2)
s.part("C18", "Device:C", "100nF TXU VCCB BYPASS", {"1": "MODEM_VDD_1V8", "2": "GND"}, block=block2)

# TI TXU0202: fixed channel A1 -> B1Y and B2 -> A2Y.
s.part("U2", "parts:TXU0202QDTTRQ1", "TXU0202DCU", {
    "1": "MODEM_TXD",       # B2 input, module TXD
    "2": "GND",
    "3": "CARRIER_3V3",        # VCCA
    "4": "MODEM_TO_MCU_RX", # A2Y output to ESP32 RX
    "5": "MCU_TO_MODEM_TX", # A1 input from ESP32 TX
    "6": "CARRIER_3V3",        # OE active high
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

# Optional 1.8V STATUS to 3.3V controller input. Pad-66 selection is mutually
# exclusive: R25 fitted for STATUS, or R28 fitted if SIMCom confirms GND.
s.part("R25", "Device:R", "4.7k STATUS BASE LINK — DNP UNTIL CONFIRMED", {"1": "MODEM_STATUS_1V8", "2": "STATUS_BASE"}, block=block2, dnp=True)
s.part("R26", "Device:R", "100k STATUS BASE PULLDOWN", {"1": "STATUS_BASE", "2": "GND"}, block=block2)
s.part("Q3", "Transistor_BJT:MMBT3904", "MMBT3904 STATUS LEVEL SHIFT", {"1": "STATUS_BASE", "2": "GND", "3": "MODEM_STATUS"}, block=block2)
s.part("R27", "Device:R", "10k STATUS COLLECTOR PULLUP", {"1": "CARRIER_3V3", "2": "MODEM_STATUS"}, block=block2)
s.part("R28", "Device:R", "0R PAD66 TO GND ALTERNATIVE — DNP", {"1": "MODEM_STATUS_1V8", "2": "GND"}, block=block2, dnp=True)

# This flag stands in for the A7670 module's VDD_1V8 power-output pin until the
# module symbol is added after SIMCom resolves the exact LASA pad map.
s.flag("MODEM_VDD_1V8", "MODEM_TXD")




# USB 2.0 device/UFP interface. Linux vision computer is the USB host.
block3 = "USB-C HOST DATA INTERFACE"
s.note(block3, "A7670 USB is a USB 2.0 device only. The Linux vision computer is the host. USB VBUS is a detection input to the modem, not a modem power input; do not connect it to MODEM_5V_SW.")
s.note(block3, "Route USB D+/D− as a 90 Ω differential pair with short stubs. ESD73011N-2/TR is a 0.4 pF data-line TVS candidate. SBU pins are unused; CC1/CC2 use 5.1 kΩ Rd for USB-C UFP mode.")

# USB-C receptacle candidate with combined A/B pad numbers matching its footprint.
s.part("J7", "parts:TYPE-C16PIN2MD_bcb96b08", "TYPE-C 16PIN 2MD(073) USB2 UFP", {
    "13": "USB_SHIELD", "14": "USB_SHIELD",
    "A1B12": "GND", "A4B9": "USB_VBUS_HOST", "A5": "USB_CC1",
    "A6": "USB_D+_CONN", "A7": "USB_D-_CONN", "A8": None,
    "B1A12": "GND", "B4A9": "USB_VBUS_HOST", "B5": "USB_CC2",
    "B6": "USB_D+_CONN", "B7": "USB_D-_CONN", "B8": None,
}, block=block3, footprint="parts:USB-C-SMD_TYPE-C-16PIN-2MD-073")

# Low-capacitance data-line ESD devices and replaceable 0-ohm links.
s.part("D4", "Device:D_TVS", "ESD73011N-2/TR USB D+ ESD 0.4pF", {"1": "USB_D+_CONN", "2": "GND"}, block=block3, footprint="parts:DFN1006-2L-BI")
s.part("D5", "Device:D_TVS", "ESD73011N-2/TR USB D- ESD 0.4pF", {"1": "USB_D-_CONN", "2": "GND"}, block=block3, footprint="parts:DFN1006-2L-BI")
s.part("D6", "Device:D_TVS", "WS07DP 7V VRWM USB VBUS TVS CANDIDATE", {"1": "USB_VBUS_HOST", "2": "GND"}, block=block3)
s.part("R14", "Device:R", "0R USB D+ LINK", {"1": "USB_D+_CONN", "2": "MODEM_USB_DP"}, block=block3)
s.part("R15", "Device:R", "0R USB D- LINK", {"1": "USB_D-_CONN", "2": "MODEM_USB_DM"}, block=block3)
s.part("R16", "Device:R", "0R USB VBUS DETECT LINK", {"1": "USB_VBUS_HOST", "2": "MODEM_USB_VBUS"}, block=block3)
s.part("R17", "Device:R", "5.1k CC1 Rd", {"1": "USB_CC1", "2": "GND"}, block=block3)
s.part("R18", "Device:R", "5.1k CC2 Rd", {"1": "USB_CC2", "2": "GND"}, block=block3)
s.part("R19", "Device:R", "0R USB SHIELD GROUND LINK", {"1": "USB_SHIELD", "2": "GND"}, block=block3)

# Logical placeholder for USB/SIM pins on the not-yet-confirmed A7670E-LASA module symbol.
s.part("J5", "Connector_Generic:Conn_01x09", "A7670E USB-SIM PORT — LOGICAL PLACEHOLDER ONLY", {
    "1": "MODEM_USB_DP", "2": "MODEM_USB_DM", "3": "MODEM_USB_VBUS",
    "4": "SIM_VDD", "5": "SIM_DATA", "6": "SIM_CLK",
    "7": "SIM_RST", "8": "SIM_DET", "9": "GND",
}, block=block3)

# Nano-SIM socket and SIMCom-style ESD / series network.
block4 = "SIM CARD INTERFACE"
s.note(block4, "Nano-SIM socket is a candidate only; verify the manufacturer's drawing, card-detect switch polarity and footprint before layout. The module provides SIM_VDD (1.8V/3.0V) and its internal 4.7k SIM_DATA pull-up; do not add another pull-up.")
s.part("J6", "parts:SMN-303", "XUNPU SMN-303 NANO-SIM SOCKET CANDIDATE", {
    "C1": "SIM_VDD", "C2": "SIM_CARD_RST", "C3": "SIM_CARD_CLK",
    "C5": "GND", "C6": None, "C7": "SIM_CARD_DATA", "CD": "SIM_DET",
    "8": "GND", "9": "GND", "10": "GND", "11": "GND",
}, block=block4, footprint="parts:SIM-SMD_SMN-303")
s.part("U4", "parts:ESDA6V1W5", "ESDA6V1W5 FOUR-LINE SIM ESD ARRAY", {
    "1": "SIM_VDD", "2": "GND", "3": "SIM_CARD_RST",
    "4": "SIM_CARD_CLK", "5": "SIM_CARD_DATA",
}, block=block4, footprint="parts:SC-70-5_L2.1-W1.3-P0.65-LS2.1-BR")
s.part("R20", "Device:R", "22R SIM RESET SERIES", {"1": "SIM_RST", "2": "SIM_CARD_RST"}, block=block4)
s.part("R21", "Device:R", "22R SIM CLOCK SERIES", {"1": "SIM_CLK", "2": "SIM_CARD_CLK"}, block=block4)
s.part("R22", "Device:R", "22R SIM DATA SERIES", {"1": "SIM_DATA", "2": "SIM_CARD_DATA"}, block=block4)
s.part("C19", "Device:C", "100nF SIM VDD LOCAL BYPASS", {"1": "SIM_VDD", "2": "GND"}, block=block4)
s.part("C20", "Device:C", "33pF SIM VDD LOCAL BYPASS", {"1": "SIM_VDD", "2": "GND"}, block=block4)

# Temporary power flags represent external host VBUS and module SIM_VDD outputs
# until the complete module symbol is integrated.
s.flag("USB_VBUS_HOST", "SIM_VDD")




# MAIN_ANT RF matching and external coax interface.
block5 = "LTE MAIN ANTENNA RF PATH"
s.note(block5, "SIMCom Figure 31: R1/R2 default 0 ohm; C1/C2 are reserved for tuning and their values come from the antenna vendor after RF tuning. Keep this path 50 ohm controlled impedance.")
s.note(block5, "J9 is a 50 ohm U.FL test/antenna connector candidate. Place it and the matching network close to module MAIN_ANT pad 60. Use a strain-relieved coax pigtail to a vehicle-rated external antenna; do not repeatedly flex the U.FL connector.")
s.note(block5, "Antenna target: omnidirectional, 50 ohm, average gain > -3 dBi, efficiency > 50%, VSWR < 2, with coverage for the exact module LTE bands. Confirm antenna and cable losses with the vendor and field test.")

# Logical module RF placeholder; replace with the exact LGA module symbol.
s.part("J8", "Connector_Generic:Conn_01x02", "A7670E MAIN_ANT / GND — LOGICAL PLACEHOLDER", {
    "1": "MODEM_MAIN_ANT", "2": "GND"
}, block=block5)

# Two series zero-ohm links and two unpopulated shunt tuning positions.
s.part("R23", "Device:R", "0R RF MATCH SERIES 1", {"1": "MODEM_MAIN_ANT", "2": "RF_MATCH_1"}, block=block5, footprint="Resistor_SMD:R_0402_1005Metric")
s.part("C21", "Device:C", "DNP RF TUNING CAP C1", {"1": "RF_MATCH_1", "2": "GND"}, block=block5, footprint="Capacitor_SMD:C_0201_0603Metric", dnp=True)
s.part("R24", "Device:R", "0R RF MATCH SERIES 2", {"1": "RF_MATCH_1", "2": "RF_MATCH_2"}, block=block5, footprint="Resistor_SMD:R_0402_1005Metric")
s.part("C22", "Device:C", "DNP RF TUNING CAP C2", {"1": "RF_MATCH_2", "2": "GND"}, block=block5, footprint="Capacitor_SMD:C_0201_0603Metric", dnp=True)
s.part("D7", "Device:D_TVS", "PESD0402-03 OPTIONAL RF TVS", {"1": "RF_MATCH_2", "2": "GND"}, block=block5, footprint="Resistor_SMD:R_0402_1005Metric", dnp=True)
s.part("J9", "parts:U_FL-R-SMT-1_10_", "HIROSE U.FL-R-SMT-1(10) 50R RF CONNECTOR", {
    "1": "RF_MATCH_2", "2": "GND"
}, block=block5, footprint="parts:U.FL_Hirose_U.FL-R-SMT-1_Vertical")

s.write("board.kicad_sch", overwrite=True)