function rx_wave = add_awgn_noise(tx_wave, snr_db)
% ADD_AWGN_NOISE Add real-valued AWGN using measured signal power.

    signal_power = mean(tx_wave .^ 2);
    snr_linear = 10 ^ (snr_db / 10);
    noise_power = signal_power / snr_linear;
    noise_std = sqrt(noise_power);
    noise = noise_std * randn(size(tx_wave));
    rx_wave = tx_wave + noise;
end
