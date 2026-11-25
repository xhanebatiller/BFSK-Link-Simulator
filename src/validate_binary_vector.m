function validate_binary_vector(values, variable_name)
%VALIDATE_BINARY_VECTOR Ensure an input is a nonempty vector of binary values.

    if ~isvector(values) || isempty(values) || any((values(:) ~= 0) & (values(:) ~= 1))
        error('%s must be a nonempty vector containing only 0 and 1.', variable_name);
    end
end
