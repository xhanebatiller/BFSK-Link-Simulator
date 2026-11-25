function crc_bits = crc8_encode(data, polynomial)
% CRC8_ENCODE Append the CRC-8 remainder using modulo-2 long division.
% The project generator polynomial is x^8 + x^2 + x + 1 (0x07).

    validate_binary_vector(data, 'data');
    validate_binary_vector(polynomial, 'polynomial');
    degree = numel(polynomial) - 1;
    if degree < 1 || polynomial(1) ~= 1
        error('polynomial must have a leading coefficient of 1.');
    end

    padded = [double(data), zeros(1, degree)];
    polynomial = double(polynomial);

    for idx = 1:numel(data)
        if padded(idx) == 1
            padded(idx:idx + degree) = xor(padded(idx:idx + degree), polynomial);
        end
    end

    crc_bits = padded(end - degree + 1:end);
end
