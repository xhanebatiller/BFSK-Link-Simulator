# Implementation Notes

## Scope

This is a MATLAB simulation, not a hardware implementation. The signal channel is modeled with real-valued additive white Gaussian noise (AWGN). The receiver uses non-coherent quadrature energy comparison for the two BFSK tones.

## CRC and ARQ

Each 100-bit payload receives an 8-bit CRC field using the generator polynomial `x^8 + x^2 + x + 1` (`0x07`), producing a 108-bit frame. The receiver performs modulo-2 division; a zero remainder accepts the frame, while a nonzero remainder requests retransmission.

The ACK/NACK exchange is represented by software control flow. A separate reverse communication channel, ACK/NACK bit waveform, and timeout model are not simulated.

## Metric definitions

- **BER:** First-transmission bit errors divided by the number of first-transmission frame bits. The denominator includes the 8 CRC bits in each 108-bit frame.
- **FER:** Fraction of frames that fail the CRC check on their first transmission.
- **Retransmissions:** Number of retransmit events recorded by the Stop-and-Wait loop.
- **Throughput:** Useful payload bits divided by all transmitted frame bits (including CRC bits and retransmissions), multiplied by the nominal payload bit rate. ACK/NACK transmission time is not included.
- **Efficiency:** Effective throughput divided by the nominal bit rate, expressed as a percentage.

## Reproducibility and runtime

The random generator is initialized with `rng(101)` to match the report's deterministic setup. The script runs 100,000 payload bits over seven SNR values. Runtime depends on the MATLAB installation and computer, with the low-SNR cases requiring many retransmissions.

A high retry-count safety guard is included to prevent an unbounded loop if an unexpected implementation or configuration problem occurs. The documented report results did not specify this guard.

## Toolbox requirements

The implementation uses standard MATLAB functions and does not call Communications Toolbox functions. The code is organized as a main function plus helper `.m` files in `src/`.
