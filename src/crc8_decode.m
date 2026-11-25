function has_error = crc8_decode(frame, polynomial)
% CRC8_DECODE Return true when the modulo-2 CRC remainder is nonzero.

    validate_binary_vector(frame, 'frame');
    validate_binary_vector(polynomial, 'polynomial');
    degree = numel(polynomial) - 1;
    if degree < 1 || polynomial(1) ~= 1
        error('polynomial must have a leading coefficient of 1.');
    end
    if numel(frame) <= degree
        error('frame must contain payload bits in addition to the CRC field.');
    end

    remainder_buffer = double(frame);
    polynomial = double(polynomial);

    for idx = 1:(numel(frame) - degree)
        if remainder_buffer(idx) == 1
            remainder_buffer(idx:idx + degree) = ...
                xor(remainder_buffer(idx:idx + degree), polynomial);
        end
    end

    has_error = any(remainder_buffer(end - degree + 1:end) ~= 0);
end
