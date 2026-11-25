function [signal, t] = encode_manchester(bits, samples_per_bit, bit_duration)
% ENCODE_MANCHESTER Manchester encoding using the IEEE 802.3 convention:
% 1 -> high-to-low; 0 -> low-to-high.

    validate_binary_vector(bits, 'bits');
    if mod(samples_per_bit, 2) ~= 0
        error('samples_per_bit must be even for Manchester encoding.');
    end

    half_samples = samples_per_bit / 2;
    signal = zeros(1, numel(bits) * samples_per_bit);

    for idx = 1:numel(bits)
        if bits(idx) == 1
            first_level = 1;
            second_level = -1;
        else
            first_level = -1;
            second_level = 1;
        end

        first_sample = (idx - 1) * samples_per_bit + 1;
        midpoint = first_sample + half_samples - 1;
        last_sample = idx * samples_per_bit;
        signal(first_sample:midpoint) = first_level;
        signal(midpoint + 1:last_sample) = second_level;
    end

    t = (0:numel(signal)-1) * (bit_duration / samples_per_bit);
end
