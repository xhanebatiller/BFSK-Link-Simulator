function rx_bits = demodulate_bfsk(wave, f0, f1, samples_per_bit, fs)
% DEMODULATE_BFSK Non-coherent quadrature-envelope BFSK detector.
% Compares I^2 + Q^2 energy for the f0 and f1 branches on each bit.

    if mod(numel(wave), samples_per_bit) ~= 0
        error('The received waveform length must be divisible by samples_per_bit.');
    end

    num_bits = numel(wave) / samples_per_bit;
    rx_bits = zeros(1, num_bits);
    t_bit = (0:samples_per_bit-1) / fs;

    cos_0 = cos(2 * pi * f0 * t_bit);
    sin_0 = sin(2 * pi * f0 * t_bit);
    cos_1 = cos(2 * pi * f1 * t_bit);
    sin_1 = sin(2 * pi * f1 * t_bit);

    for idx = 1:num_bits
        sample_range = (idx - 1) * samples_per_bit + (1:samples_per_bit);
        segment = wave(sample_range);

        I0 = sum(segment .* cos_0);
        Q0 = sum(segment .* sin_0);
        E0 = I0^2 + Q0^2;

        I1 = sum(segment .* cos_1);
        Q1 = sum(segment .* sin_1);
        E1 = I1^2 + Q1^2;

        rx_bits(idx) = double(E1 > E0);
    end
end
