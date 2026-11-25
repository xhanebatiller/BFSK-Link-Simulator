function [signal, t] = encode_nrz_l(bits, samples_per_bit, bit_duration)
% ENCODE_NRZ_L Map 1 -> +1 V and 0 -> -1 V using NRZ-L line coding.

    validate_binary_vector(bits, 'bits');
    mapped = 2 * double(bits) - 1;
    signal = repelem(mapped, samples_per_bit);
    t = (0:numel(signal)-1) * (bit_duration / samples_per_bit);
end
