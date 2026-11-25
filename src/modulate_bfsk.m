function wave = modulate_bfsk(bits, f0, f1, samples_per_bit, fs)
% MODULATE_BFSK Generate a binary FSK passband waveform.
% Binary 0 uses f0; binary 1 uses f1. With the project parameters,
% both tones complete an integer number of cycles in each bit interval.

    validate_binary_vector(bits, 'bits');
    t_bit = (0:samples_per_bit-1) / fs;
    wave = zeros(1, numel(bits) * samples_per_bit);

    for idx = 1:numel(bits)
        if bits(idx) == 1
            carrier_frequency = f1;
        else
            carrier_frequency = f0;
        end
        sample_range = (idx - 1) * samples_per_bit + (1:samples_per_bit);
        wave(sample_range) = cos(2 * pi * carrier_frequency * t_bit);
    end
end
