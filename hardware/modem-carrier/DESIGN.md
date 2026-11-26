# Edu Ride A7670E-LASA LTE Carrier — Design Definition

## Goal

A separate prototype daughterboard for the Edu Ride bus controller. It hosts a SIMCom A7670E-LASA LTE Cat 1 modem, provides a safe 3.8 V high-current supply, translates modem logic to the ESP32-S3 controller, accepts a nano-SIM, and exposes a USB 2.0 device connection for an optional Linux vision computer. The existing ESP32-S3 controller PCB is not modified by this project.

The modem is intended for controller telemetry and, where required, a direct USB data connection to the Linux vision computer. It is not a substitute for a higher-bandwidth Cat 4/5G link where sustained image/video uploads exceed Cat 1 capacity.

## Who builds it and project stage

Prototype engineering board. Initial assumption: factory SMT assembly for the 24 x 24 mm LGA modem, QFN power IC and fine-pitch logic ICs. Hand assembly is not the baseline. No manufacturing release is authorized.

## Supplies and load budget

| Rail | Nominal | Source | Load / design basis |
|---|---:|---|---|
| MODEM_5V_IN | 5.0 V | Existing controller J14 protected MODEM_5V_EXT | Reserve up to 3 A at the carrier input; controller connector, Q1, copper and upstream source must be verified before release |
| MODEM_VBAT | 3.8 V | Carrier synchronous buck | A7670 family conservative peak design basis 2.8 A; 10.64 W peak at 3.8 V |
| MODEM_VDD_EXT | 1.8 V | A7670 module output | Logic-side supply only after the module's output-current budget and sequencing are confirmed |
| HOST_USB_VBUS | 5 V nominal | Linux host USB port | USB presence / module VBUS interface only; must not back-feed the host or the carrier 5 V rail |
| ESP32_LOGIC | 3.3 V | Controller J2 signal domain | UART and control logic reference; no 3.3 V power is taken from J2 |

At 3.8 V × 2.8 A, modem peak output power is 10.64 W. At 5 V input and an assumed 90% conversion efficiency, input current is approximately 2.36 A (10.64 W / 5 V / 0.90). This is a sizing estimate, not a measured efficiency result. Reserve a 3 A capable 5 V feed and verify its full path under burst load.

SIMCom A7670 Series Hardware Design V1.00 states 3.4–4.2 V VBAT, 3.8 V typical, 2.8 A peak, less than 300 mV burst droop, and recommends at least 300 µF external capacitance when the supply can provide the 2.8 A peak (otherwise at least 1000 µF). Use the 2.8 A family figure as a conservative design envelope until the exact A7670E-LASA revision's own hardware guide is confirmed. The local modem bulk capacitor bank must be at least 300 µF effective at 3.8 V, with low-ESR parts and local ceramics; account for DC-bias derating.

## Blocks

J14 protected 5 V + GND → input protection / current measurement link → 3.8 V / 5 A-class synchronous buck → local bulk and ceramic capacitors → A7670E-LASA VBAT pins.

Controller J2 UART TX/RX → TXU0202 dual-supply fixed-direction translator (3.3 V ESP32 side, 1.8 V modem side) → modem UART RXD/TXD.

Controller J2 PWRKEY and RESET → separate low-side open-drain transistor stages → modem active-low control pins.

Modem STATUS (1.8 V) → dedicated 1.8-to-3.3 V translator → controller J2 STATUS input.

Nano-SIM socket → SIM ESD protection → modem SIM_VDD / SIM_DATA / SIM_CLK / SIM_RST; card detect may be wired to a modem GPIO only after exact pin and firmware requirements are checked.

Modem RF_ANT → controlled 50 Ω RF trace → matching / ESD network as SIMCom specifies → u.FL/I-PEX connector → approved LTE antenna. Maintain the module and antenna keep-outs from the hardware design guide.

Modem USB_DP / USB_DM → USB 2.0 ESD device → 90 Ω differential pair → USB device connector to Linux vision computer. Host VBUS is handled only as specified by SIMCom; no power back-feed.

## Existing controller interfaces (do not change)

### J2 six-pin signal header

| J2 pin | Controller signal | ESP32-S3 GPIO | Carrier function |
|---:|---|---:|---|
| 1 | GND | — | Common ground |
| 2 | MCU_TO_MODEM_TX | GPIO15 | 3.3 V ESP TX → translator A1 → 1.8 V modem RXD |
| 3 | MODEM_TO_MCU_RX | GPIO16 | 1.8 V modem TXD → translator B2 → 3.3 V ESP RX |
| 4 | MODEM_PWRKEY | GPIO38 | Drives open-drain PWRKEY stage; exact polarity/timing from purchased module revision |
| 5 | MODEM_RESET | GPIO39 | Drives open-drain RESET stage; exact polarity/timing from purchased module revision |
| 6 | MODEM_STATUS | GPIO40 | Receives translated 1.8 V STATUS signal |

J14 is the separate two-terminal protected 5 V modem input. Its pin polarity and current capability must be re-read from the current controller schematic and confirmed on the physical assembly. Do not assume J14 can sustain the calculated 2.4–3 A input without verification.

## Candidate parts — not yet released

| Function | Candidate | Reason / status |
|---|---|---|
| Modem | SIMCom A7670E-LASA | Selected candidate; exact module revision, pad drawing and stock must be checked before footprint release |
| 3.8 V buck | Analog Devices LT8640EUDC#TRPBF | 5 A continuous / 7 A peak transient family capability; 3.4–42 V input. Candidate only; calculate 3.8 V feedback, switching frequency, inductor, input/output capacitors and thermal behavior from the current datasheet |
| UART translator | TI TXU0202DCU | Two channels with opposite fixed directions; A1→B1Y for ESP TX→modem RX, B2→A2Y for modem TX→ESP RX; VCCA=3.3 V, VCCB=1.8 V. Confirm VDD_EXT capability and startup sequencing |
| STATUS translator | TI SN74AXC1T45DBV | Candidate one-bit translator for modem STATUS 1.8 V→ESP32 3.3 V; confirm direction pin, OE behavior and pin table |
| SIM socket | XUNPU SMN-303 | Candidate nano-SIM push-push with card detect; footprint and card pin mapping must be checked against its manufacturer drawing |

Do not reuse the PCB library's LT8640 EasyEDA footprint without checking it against the official Analog Devices UDC package drawing. The LT8640 has missing physical lead positions 5 and 12 and an exposed pad assigned to SW (pins 21 and 22), not GND. A generic 20-pad QFN footprint or a conventional grounded thermal pad would be wrong.

The A7670E-LASA has no trusted PCBKit footprint. Create a project-local footprint only from the exact SIMCom A7670E-LASA land-pattern drawing, with pad dimensions, pitch, pad numbering, central ground pads, RF pad and stencil windows independently measured. Do not use the 24 x 24 mm body outline as a substitute for the land pattern.

## What it also needs

### In
- 3.8 V and 5 V test pads, ground probe point, and current-measurement link in the modem power path.
- Local 300 µF minimum effective VBAT bulk plus ceramics, placed at the module VBAT pins.
- Input reverse-polarity / transient protection appropriate to the controller's already-protected 5 V output, without duplicating a series drop that consumes buck headroom.
- SIM and USB ESD protection close to user-accessible connectors.
- RF connector, antenna keep-out and the exact matching network specified by SIMCom.
- A way to isolate the modem supply for bench bring-up and current measurement.
- Clear connector labels and polarity, board revision, and accessible test points.

### Left out / limitations
- No onboard camera, image recognition, or student biometric storage; those remain with the separate Linux vision computer/backend architecture.
- No direct connection from ESP32 UART to a camera or bulk image stream.
- No onboard battery charger or battery; carrier is powered from controller J14.
- No automotive transient compliance claim; the 5 V source is assumed to be a regulated protected controller rail. Vehicle supply protection remains a separate system-level validation item.
- No antenna included until LTE antenna band coverage, connector, cable, mounting position and enclosure are chosen.

## What the program must know and control

| Question / action | How the board answers | Controller pin |
|---|---|---|
| Send AT commands | 3.3 V TX translated to modem 1.8 V RXD | GPIO15 via J2 pin 2 |
| Receive modem responses | modem 1.8 V TXD translated to ESP32 3.3 V RX | GPIO16 via J2 pin 3 |
| Request modem power-on / off sequence | low-side open-drain transistor on PWRKEY | GPIO38 via J2 pin 4 |
| Request modem reset | low-side open-drain transistor on RESET | GPIO39 via J2 pin 5 |
| Read modem status | 1.8 V STATUS translated to 3.3 V | GPIO40 via J2 pin 6 |
| Know 3.8 V rail is present | power-good signal from buck, if pin budget permits; otherwise test point only | TBD; do not consume an ESP32 GPIO without confirming availability |
| Linux host data path | USB 2.0 D+/D− to host connector | USB connector; not ESP32 UART |

## Layers

Initial recommendation: four-layer prototype. L1 components, short high-current paths and RF; L2 continuous GND reference; L3 power distribution and slow signals; L4 secondary signals. RF feed is 50 Ω and USB pair 90 Ω differential only after the fabricator stack-up is fixed and the field solver verifies widths/gaps. Keep copper clear beneath the antenna region exactly as the module and antenna guides require. The 3.8 V switch node and inductor must be kept away from RF and SIM lines.

## Decisions and source basis

- Modem peak current and bulk-capacitance design envelope: SIMCom A7670 Series Hardware Design V1.00, power-supply section (pp. 22–23 in the downloaded document). Conservative 2.8 A until exact A7670E-LASA revision is reconciled.
- LT8640 capability and package: Analog Devices LT8640/LT8640-1 datasheet, current revision; 5 A continuous and 7 A peak transient; 3.4–42 V input. Use official package drawing and reference circuit, not a generic footprint.
- UART level translation: TI TXU0202 datasheet; dual-supply, two fixed-direction channels in opposite directions, 1.1–5.5 V rails.
- Carrier USB host port is included to allow a Linux vision computer to use the modem independently of ESP32 UART. Cat 1 remains limited bandwidth and requires field testing on the intended route/operator.

## Not verified

- Exact A7670E-LASA-specific hardware design guide and revision, complete 88-pad assignment, recommended land pattern and central pad details.
- Whether A7670E-LASA VDD_EXT can safely power the selected translators through all startup and shutdown conditions.
- LT8640 feedback resistor values, switching frequency, inductor saturation/current rating, input/output capacitor effective values, loop stability and thermal dissipation at 5 V→3.8 V / 2.8 A.
- Controller J14 connector, Q1 reverse-protection FET, tracks, vias, cable and upstream 5 V source current capacity.
- Exact PWRKEY / RESET polarity, timing and electrical requirements for the purchased module revision.
- SIM socket exact mechanical drawing and SIM pin mapping.
- RF matching, antenna performance, RF keep-out, LTE bands and installation performance in the vehicle.
- USB VBUS interface, Type-C CC requirements (if USB-C is selected), ESD device capacitance and signal-integrity margin.
- PCB schematic/ERC, board connectivity, DRC, impedance, thermal, EMC, bench power-up and network tests.

## First power-up (draft; complete after schematic and layout)

1. Inspect module orientation, SIM socket, regulator, inductor and all polarities.
2. With no modem fitted, measure resistance from 5 V, 3.8 V, 1.8 V and GND; inspect for shorts.
3. Feed 5 V from a current-limited bench supply with a conservative limit; verify no unexpected current.
4. Test the 3.8 V rail with an electronic load in steps, including 2.8 A transient pulses; record droop and recovery at the module VBAT pads.
5. Verify 1.8 V and 3.3 V translator rails and signal levels with modem unpowered and powered to check back-powering.
6. Fit modem only after the power rail passes; verify PWRKEY/RESET waveforms and UART at low baud first.
7. Test SIM detection, network registration, RF and USB host data path only after electrical checks.

This project is a prototype design definition, not a released PCB or an approved vehicle installation.

## Manufacturer-guide reconciliation — SIMCom A7670 Series Hardware Design V1.03

The newer V1.03 hardware guide explicitly includes A7670E in its 88-pad pin assignment table. It specifies VBAT pins 55/56/57, 3.4–4.2 V operating range, 3.8 V typical, and a 2 A peak-current figure; the test setup uses 330 µF at the module supply. The older V1.00 guide gives a 2.8 A peak and recommends ≥300 µF when the supply can deliver the peak. Until the exact A7670E-LASA module revision is confirmed by SIMCom, retain the conservative 2.8 A design envelope and ≥300 µF effective local capacitance. The LT8640 5 A / 7 A capability is intentionally selected with margin; this does not waive rail droop or thermal testing.

The V1.03 guide further confirms:
- Pin 15 VDD_1V8 is a module output, on by default, up to 50 mA. It can supply the 1.8 V translator rail only after power-sequencing and startup behavior are validated.
- Pin 1 PWRKEY and pin 16 RESET are active-low inputs with internal 50 kΩ pull-ups to VBAT. Their VIH is specified as 0.7 × VBAT and VIL ≤0.5 V. Use open-drain transistor stages; never connect ESP32 3.3 V directly. Do not place capacitors above 10 nF on PWRKEY or RESET.
- PWRKEY power-on pulse is typically 50 ms; the STATUS signal goes high when initialization is ready (typical 11.2 s). Power-off pulse is at least 2.5 s. RESET pulse is 2–2.5 s and should be reserved for emergency recovery, not routine power control.
- Pin 66 STATUS indicates initialized/ready state, 1.8 V domain. Translate to ESP32 3.3 V.
- UART pins 9 TXD and 10 RXD are 1.8 V. The full-function UART supports RTS/CTS, but the existing controller J2 only provides TX/RX; leave RTS/CTS open as SIMCom permits when unused.
- USB pins 27 USB_DP and 28 USB_DM form a USB 2.0 device/slave interface; the modem does not support USB host mode. The carrier's USB connector must connect to a Linux host computer, not another USB device. Route 90 Ω differential, protect at the connector, and connect host VBUS to module pin 24 only as the SIMCom reference design requires. Do not back-feed the host.
- SIM pins 30 SIM_VDD, 31 SIM_DATA, 32 SIM_CLK, 33 SIM_RST, 34 SIM_DET. SIMCom recommends ESD protection beside the socket and shows 22 Ω series resistors on SIM_RST, SIM_CLK and SIM_DATA, with local SIM_VDD decoupling. Use the exact module guide's reference circuit and the selected socket's verified contact numbering.
- Pin 60 RF_ANT is the main antenna interface. Follow the SIMCom RF matching, grounding, 50 Ω routing, and antenna requirements; do not assume a connector alone is sufficient.
- The manufacturer footprint recommendation is a 25 × 25 mm land-pattern envelope around a 24 × 24 mm module, with 88 electrical pads including the central ground-pad array and explicit forbidden/mold/keep-out regions. The footprint must be transcribed from the manufacturer drawing (V1.03 Figure 5) and checked pad-by-pad against the pin assignment (Figure 2 / Table 4). No footprint has yet been created or approved.

The USB-C connector is the preferred external host connector for the Linux vision computer. If USB-C is used, include separate 5.1 kΩ Rd resistors from CC1 and CC2 to GND, a USB 2.0 ESD part with low capacitance, and a VBUS isolation/current-limiting strategy that prevents the host's 5 V from feeding the carrier's 5 V modem input. The USB port is a modem data path only; it does not make the modem a USB host.
