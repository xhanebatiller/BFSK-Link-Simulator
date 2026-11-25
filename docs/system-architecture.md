# System Architecture

The project models a digital communication link with a physical-layer BFSK modem and a data-link reliability mechanism.

```mermaid
flowchart TD
    A[Random binary payload] --> B[100-bit payload framing]
    B --> C[CRC-8 encoder]
    C --> D[BFSK modulator\n0: 3 kHz | 1: 4 kHz]
    D --> E[AWGN channel]
    E --> F[Non-coherent quadrature BFSK demodulator]
    F --> G[CRC-8 decoder]
    G --> H{CRC remainder is zero?}
    H -- Yes / ACK --> I[Accept frame\nMove to next payload]
    H -- No / NACK --> J[Retransmit same frame]
    J --> D
```

## Signal and frame parameters

| Parameter | Value |
|---|---:|
| Payload bits | 100,000 |
| Payload per frame | 100 bits |
| CRC field | 8 bits |
| Transmitted frame length | 108 bits |
| Bit rate | 1,000 bits/s |
| Bit duration | 1 ms |
| Sampling frequency | 20,000 Hz |
| Samples per bit | 20 |
| BFSK tone for bit 0 | 3,000 Hz |
| BFSK tone for bit 1 | 4,000 Hz |
| SNR sweep | -6, -4, -2, 0, 2, 4, 6 dB |
| CRC generator | x^8 + x^2 + x + 1 (0x07) |

## Implementation detail

The NRZ-L and Manchester encoders are implemented and plotted to compare baseband line-coding waveforms. In the MATLAB implementation shown in the report, the CRC-framed bit stream is passed directly to the BFSK modulator; the line-coded waveforms are not used as the BFSK modulator input.
