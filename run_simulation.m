function results = run_simulation()
% RUN_SIMULATION  Run the BFSK digital communication system simulation.
%
% This project is implemented with base MATLAB functions and does not
% require the Communications Toolbox.
%
% Run from MATLAB:
%   results = run_simulation;
%
% The script reproduces the processing flow documented in the project
% report and saves generated figures and a metrics CSV under results/.

    clc;
    close all;

    projectRoot = fileparts(mfilename('fullpath'));
    srcDir = fullfile(projectRoot, 'src');
    outputDir = fullfile(projectRoot, 'results', 'generated');
    addpath(srcDir);

    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    %% Simulation parameters (based on the project report)
    N_bits = 100000;             % Total payload bits
    seed = 101;                  % Fixed seed for reproducibility
    fs = 20000;                  % Sampling frequency (Hz)
    Rb = 1000;                   % Payload bit rate (bits/s)
    Tb = 1 / Rb;                 % Bit duration (s)
    Ns = fs / Rb;                % Samples per bit
    f0 = 3000;                   % Carrier for binary 0 (Hz)
    f1 = 4000;                   % Carrier for binary 1 (Hz)
    frame_payload_len = 100;     % Payload bits per frame
    poly_crc8 = [1 0 0 0 0 0 1 1 1]; % x^8 + x^2 + x + 1 (0x07)
    snr_db_range = -6:2:6;       % SNR sweep (dB)
    max_attempts_per_frame = 1000000; % Safety guard against endless retries

    validate_parameters(N_bits, fs, Rb, Ns, f0, f1, frame_payload_len);

    %% Part A: Binary data generation
    rng(seed);
    tx_bits = randi([0, 1], 1, N_bits);

    fprintf('=====================================================\n');
    fprintf('BINARY DATA GENERATION\n');
    fprintf('=====================================================\n');
    fprintf('Generated %d random binary bits.\n', N_bits);
    fprintf('First 100 bits:\n');
    disp(tx_bits(1:100));

    %% Part B: Line coding visualization
    bits_vis = tx_bits(1:20);
    [nrz_vis, t_vis] = encode_nrz_l(bits_vis, Ns, Tb);
    [man_vis, ~] = encode_manchester(bits_vis, Ns, Tb);

    fig = figure('Name', 'Line Coding Signals', 'NumberTitle', 'off');
    subplot(2, 1, 1);
    plot(t_vis * 1000, nrz_vis, 'LineWidth', 2);
    grid on;
    ylim([-1.5, 1.5]);
    title('NRZ-L Encoded Waveform (First 20 Bits)');
    xlabel('Time (ms)');
    ylabel('Voltage (V)');

    subplot(2, 1, 2);
    plot(t_vis * 1000, man_vis, 'LineWidth', 2);
    grid on;
    ylim([-1.5, 1.5]);
    title('Manchester Encoded Waveform (IEEE 802.3 Convention)');
    xlabel('Time (ms)');
    ylabel('Voltage (V)');
    saveas(fig, fullfile(outputDir, 'line_coding_waveforms.png'));

    %% Part C: BFSK modulation visualization
    bfsk_vis = modulate_bfsk(bits_vis, f0, f1, Ns, fs);

    fig = figure('Name', 'BFSK Modulation', 'NumberTitle', 'off');
    plot(t_vis * 1000, bfsk_vis, 'LineWidth', 1.2);
    grid on;
    title('BFSK Modulated Waveform (First 20 Bits)');
    xlabel('Time (ms)');
    ylabel('Amplitude (V)');
    saveas(fig, fullfile(outputDir, 'bfsk_modulated_waveform.png'));

    %% Parts D-G: AWGN, CRC-8, Stop-and-Wait ARQ, and performance metrics
    num_frames = N_bits / frame_payload_len;
    num_snr_points = numel(snr_db_range);

    ber_results = zeros(1, num_snr_points);
    fer_results = zeros(1, num_snr_points);
    throughput_results = zeros(1, num_snr_points);
    retransmissions_list = zeros(1, num_snr_points);

    fprintf('\n=====================================================\n');
    fprintf('SYSTEM SIMULATION & PERFORMANCE METRICS\n');
    fprintf('=====================================================\n');

    for s_idx = 1:num_snr_points
        snr_db = snr_db_range(s_idx);

        total_bits_sent_channel = 0;
        total_bit_errors_first_try = 0;
        total_physical_bits_first_try = 0;
        total_retransmissions = 0;
        failed_first_try_frames = 0;

        for frame_idx = 1:num_frames
            start_idx = (frame_idx - 1) * frame_payload_len + 1;
            end_idx = frame_idx * frame_payload_len;
            payload = tx_bits(start_idx:end_idx);

            % Part E: Append the CRC-8 frame check sequence.
            crc_bits = crc8_encode(payload, poly_crc8);
            tx_frame = [payload, crc_bits];
            frame_len = numel(tx_frame);

            % Part F: Stop-and-Wait ARQ. A frame is retried until its CRC passes.
            frame_ack = false;
            attempts = 0;

            while ~frame_ack
                attempts = attempts + 1;
                if attempts > max_attempts_per_frame
                    error(['Frame %d exceeded the retry safety limit at SNR %g dB. ' ...
                           'Check the channel and CRC implementation.'], frame_idx, snr_db);
                end

                total_bits_sent_channel = total_bits_sent_channel + frame_len;

                % Part C: BFSK modulation of the framed bit sequence.
                tx_wave = modulate_bfsk(tx_frame, f0, f1, Ns, fs);

                % Part D: Additive White Gaussian Noise channel.
                rx_wave = add_awgn_noise(tx_wave, snr_db);

                % Part C: Non-coherent quadrature BFSK demodulation.
                rx_frame = demodulate_bfsk(rx_wave, f0, f1, Ns, fs);

                % Measure physical-layer BER using first transmissions only.
                if attempts == 1
                    bit_errors = sum(tx_frame ~= rx_frame);
                    total_bit_errors_first_try = total_bit_errors_first_try + bit_errors;
                    total_physical_bits_first_try = total_physical_bits_first_try + frame_len;
                end

                % Part E: Receiver-side CRC check.
                crc_error = crc8_decode(rx_frame, poly_crc8);

                if ~crc_error
                    frame_ack = true; % ACK: accept frame and continue
                else
                    if attempts == 1
                        failed_first_try_frames = failed_first_try_frames + 1;
                    end
                    total_retransmissions = total_retransmissions + 1; % NACK: retry
                end
            end
        end

        % BER denominator includes the full first-transmission frames,
        % including their 8-bit CRC fields.
        ber_results(s_idx) = total_bit_errors_first_try / total_physical_bits_first_try;
        fer_results(s_idx) = failed_first_try_frames / num_frames;
        throughput_results(s_idx) = (N_bits / total_bits_sent_channel) * Rb;
        retransmissions_list(s_idx) = total_retransmissions;

        fprintf(['SNR: %2d dB | BER: %.5f | FER: %.4f | Retransmissions: %d | ' ...
                 'Throughput: %6.1f bps\n'], ...
                 snr_db, ber_results(s_idx), fer_results(s_idx), ...
                 total_retransmissions, throughput_results(s_idx));
    end

    efficiency_results = (throughput_results / Rb) * 100;

    %% Performance plots
    fig = figure('Name', 'BER and Throughput vs. SNR', 'NumberTitle', 'off');
    subplot(2, 1, 1);
    % A small plotting floor makes a measured BER of exactly zero visible
    % on the logarithmic axis; the stored BER result remains exactly zero.
    ber_for_plot = max(ber_results, 1e-6);
    semilogy(snr_db_range, ber_for_plot, '-o', 'LineWidth', 2, 'MarkerSize', 6);
    grid on;
    title('Physical-Layer BER vs. SNR');
    xlabel('SNR (dB)');
    ylabel('Bit Error Rate (BER)');

    subplot(2, 1, 2);
    plot(snr_db_range, throughput_results, '-s', 'LineWidth', 2, 'MarkerSize', 6);
    grid on;
    title('Effective System Throughput vs. SNR');
    xlabel('SNR (dB)');
    ylabel('Throughput (bps)');
    saveas(fig, fullfile(outputDir, 'ber_and_throughput_vs_snr.png'));

    fig = figure('Name', 'FER vs. SNR', 'NumberTitle', 'off');
    plot(snr_db_range, fer_results, '-o', 'LineWidth', 2, 'MarkerSize', 6);
    grid on;
    ylim([0, 1.05]);
    title('Frame Error Rate vs. SNR');
    xlabel('SNR (dB)');
    ylabel('Frame Error Rate (FER)');
    saveas(fig, fullfile(outputDir, 'fer_vs_snr.png'));

    fig = figure('Name', 'Efficiency vs. SNR', 'NumberTitle', 'off');
    plot(snr_db_range, efficiency_results, '-s', 'LineWidth', 2, 'MarkerSize', 6);
    grid on;
    ylim([0, 100]);
    title('Transmission Efficiency vs. SNR');
    xlabel('SNR (dB)');
    ylabel('Efficiency (%)');
    saveas(fig, fullfile(outputDir, 'efficiency_vs_snr.png'));

    %% Export metrics
    results = struct();
    results.snr_db = snr_db_range;
    results.ber = ber_results;
    results.fer = fer_results;
    results.retransmissions = retransmissions_list;
    results.throughput_bps = throughput_results;
    results.efficiency_percent = efficiency_results;

    csv_path = fullfile(outputDir, 'simulation_metrics.csv');
    write_metrics_csv(csv_path, results);

    fprintf('\nGenerated files are saved in: %s\n', outputDir);
end

function validate_parameters(N_bits, fs, Rb, Ns, f0, f1, frame_payload_len)
    if mod(N_bits, frame_payload_len) ~= 0
        error('N_bits must be an integer multiple of frame_payload_len.');
    end
    if mod(Ns, 1) ~= 0 || Ns < 2
        error('Samples per bit (Ns) must be an integer of at least 2.');
    end
    if mod(Ns, 2) ~= 0
        error('Ns must be even for Manchester encoding.');
    end
    if fs <= 2 * max(f0, f1)
        error('Sampling frequency must exceed twice the highest carrier frequency.');
    end
    if f0 <= 0 || f1 <= 0 || f0 == f1 || Rb <= 0
        error('Carrier frequencies and bit rate must be positive; f0 and f1 must differ.');
    end
end

function write_metrics_csv(file_path, results)
    file_id = fopen(file_path, 'w');
    if file_id == -1
        error('Could not open metrics output file: %s', file_path);
    end
    cleanup = onCleanup(@() fclose(file_id)); %#ok<NASGU>
    fprintf(file_id, 'SNR_dB,BER,FER,Retransmissions,Throughput_bps,Efficiency_percent\n');
    for idx = 1:numel(results.snr_db)
        fprintf(file_id, '%g,%.8f,%.8f,%d,%.4f,%.4f\n', ...
            results.snr_db(idx), results.ber(idx), results.fer(idx), ...
            results.retransmissions(idx), results.throughput_bps(idx), ...
            results.efficiency_percent(idx));
    end
end
