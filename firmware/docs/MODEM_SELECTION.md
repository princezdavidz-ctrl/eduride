# Edu Ride Modem Selection — Engineering Decision Record

**Status:** Preferred candidate selected for controller telemetry; carrier-board and power-stage design remain open.  
**Preferred module:** SIMCom A7670E-LASA (LTE Cat 1, no GNSS variant).  
**PCB baseline:** Edu-Ride-Bus-Tracker-4L.kicad_pcb, prototype only.

## 1. Selection rationale

The controller modem is intended for compact telemetry: trip state, GNSS metadata, health/fault events and small control-plane messages. It is not the transport for raw camera streams or bulk student imagery. The Vision + GPS Linux computer requires its own independently validated high-bandwidth uplink; it must not depend on forwarding images through the ESP32-S3 UART.

A7670E supports LTE Cat 1 with up to 10 Mbps downlink / 5 Mbps uplink and LTE-FDD bands B1/B3/B5/B7/B8/B20. It also supports GSM 900/1800 fallback. Current Kenyan spectrum allocation data lists LTE B20 (800 MHz), B3 (1800 MHz) and B1 (2100 MHz) for major operators including Safaricom and Airtel; the module therefore has relevant band overlap. This allocation is not proof of live service at every bus route: field tests with the intended operator SIMs remain mandatory.

Select the **A7670E-LASA** variant (not a generic A7670 label) for the next carrier-board design because the controller already has a separate GNSS receiver. The LASA variant avoids paying for/depending on a second GNSS function. Confirm the exact module label, firmware variant and band table with the supplier before procurement.

## 2. Candidate comparison

| Candidate | Radio/data | Kenya band fit | Power/interface impact | Decision |
|---|---|---|---|---|
| SIMCom A7670E-LASA | LTE Cat 1, 10/5 Mbps; GSM fallback | LTE B1/B3/B20; GSM 900/1800 | 3.4–4.2 V VBAT, design for 2.8 A peak; 1.8 V UART/control domain | **Preferred for controller telemetry** |
| Quectel EG25-G | LTE Cat 4, up to 150/50 Mbps; 2G/3G fallback | LTE B1/B3/B20/B28 and TDD B38–B41 | 3.3–4.3 V, 3.8 V typical; manufacturer reference supply sized up to 3 A; more interfaces/complexity | Alternative if the controller later needs higher data throughput |

Cat 4 is not selected for this UART-only controller because its extra throughput is not useful for the event-metadata workload. If the Linux vision computer is ever expected to use this modem directly, the architecture must use the modem's USB interface and a host-capable computer; the existing J2 UART connection is not an image-data path.

## 3. Recovered controller-board interface

PCBKit inspection of the four-layer prototype confirms:

**J2**
1. GND
2. MCU_TO_MODEM_TX (ESP32-S3 GPIO15)
3. MODEM_TO_MCU_RX (ESP32-S3 GPIO16)
4. MODEM_PWRKEY (GPIO38)
5. MODEM_RESET (GPIO39)
6. MODEM_STATUS (GPIO40)

**Separate modem power terminals**
- J13 supplies MODEM_5V_RAW (external 5 V input).
- J14 exposes MODEM_5V_EXT after the Q1 AO3401A reverse-polarity stage.
- CbulkModem1 is only 22 µF on MODEM_5V_EXT.
- J2 has no power pin.
- The current source description labels the modem power nets as 5 V / 3 A, but this is a design declaration, not proof that the assembled terminal, Q1, copper, connector and source can sustain the required transient current.

## 4. Required carrier-board architecture

Use a dedicated modem carrier/daughterboard between J2 and the A7670E-LASA. Do not connect the bare LGA module directly to the controller.

The carrier must provide:
1. A regulated 3.8 V VBAT rail from the 5 V modem input, designed for at least 2.8 A transient output and controlled droop.
2. At least 300 µF suitable low-ESR local bulk capacitance at the module VBAT pins, plus the ceramic bypass network in the current SIMCom hardware design. SIMCom recommends at least 300 µF when the supply can deliver 2.8 A; if it cannot, the design guide calls for at least 1000 µF to limit burst droop. Prefer a supply that can actually deliver the peak rather than relying on capacitance alone.
3. 1.8 V ↔ 3.3 V UART level translation. A7670 UART pins are specified as 1.8 V; do not connect them directly to ESP32-S3 3.3 V GPIO.
4. Safe open-drain/transistor control of active-low PWRKEY and RESET. Do not drive these pins from ESP32 GPIO until the selected carrier's circuit and powered-off behavior are verified.
5. Level translation for the 1.8 V modem STATUS output before it reaches ESP32 GPIO40.
6. SIM socket, SIM ESD protection, RF connector and an LTE antenna matched to the installed vehicle/enclosure.
7. Test points for 5 V input, 3.8 V VBAT, 1.8 V I/O, UART TX/RX and status/control signals.

The existing 22 µF on the controller's 5 V external rail is not the module's required VBAT burst capacitor. The carrier must include its own power conditioning and local energy storage.

## 5. Firmware configuration decision

- Keep `CONFIG_ER_ENABLE_CELLULAR_LINK=n` until the carrier board is built and verified.
- The A7670E full-function UART default is 115200 baud. Set a modem-specific Kconfig baud only after confirming the purchased module/firmware and carrier design.
- Implement the modem adapter separately from `cellular_link.c`; generic state reporting remains hardware-independent.
- PWRKEY/RESET timing, polarity, UART framing and status behavior must follow the exact A7670E datasheet revision and the carrier circuit.
- Do not start `er_event_uploader_start()` until SIM/network registration, packet data, secure provisioning, TLS root CA and backend endpoint are verified.

## 6. Release gates

1. Supplier confirms A7670E-LASA exact part/firmware and LTE band support.
2. Carrier-board schematic and layout reviewed against SIMCom hardware design.
3. 5 V source, Q1, terminals, copper and connector transient-current capability verified.
4. 3.8 V VBAT measured at module pins during LTE attach and 2G transmit bursts; remain within 3.4–4.2 V and within SIMCom's burst-droop guidance.
5. UART and control logic levels measured; no 1.8 V/3.3 V direct-connection assumptions.
6. SIM and carrier tests on Safaricom and Airtel (or the selected service operators) on actual bus routes.
7. GNSS, LTE antenna isolation, enclosure, EMC and thermal validation.
8. Firmware parser/driver build and hardware bench tests, followed by secure backend event-upload tests.

**No modem has been ordered, no carrier board has been designed, and no modem hardware test has been performed. This is a documented engineering selection, not a release approval.**

## 7. Reference documents

- SIMCom A7670 Series Hardware Design V1.00: https://makerselectronics.com/wp-content/uploads/2025/09/A7670-Series-Hardware-Design_V1.00.pdf
- SIMCom A7670 Series Specification: https://d3s5r33r268y59.cloudfront.net/datasheets/36332/2024-11-04-06-40-22/A7670_Series_SPEC_20200527.pdf
- Quectel EG25-G specification: https://www.quectel.com/content/uploads/2024/03/Quectel_EG25-G_LTE_Standard_Specification_V1.6-1-1.pdf
- Kenya Communications Authority frequency allocation material: https://www.ca.go.ke/sites/default/files/CA/Licensing%20Procedures/National%20Table%20of%20Frequency%20Allocations%202024.pdf
- Kenya spectrum allocation reference (operator breakdown): https://www.spectrum-tracker.com/kenya
