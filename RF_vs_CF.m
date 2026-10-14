% =========================================================================
% Script Dinâmico para Plotar Sweep do LTspice (Protegido contra erros RGB)
% =========================================================================

% Limpa a área de trabalho, fecha gráficos abertos e limpa o console
clear; close all; clc; 

filename = 'dados_sweep.txt'; % Nome do arquivo exportado do LTspice

% Lê o arquivo inteiro como texto e divide por linhas
filetext = fileread(filename);
file_lines = splitlines(filetext);

% Variáveis para armazenar todas as curvas antes de plotar
curves = {}; 
current_freqs = [];
current_mags = [];
current_label = 'Curva Nominal'; 

% --- FASE 1: LEITURA E EXTRAÇÃO DINÂMICA DOS DADOS ---
for i = 1:length(file_lines)
    line = strtrim(file_lines{i});
    
    % Ignora linhas em branco ou cabeçalhos
    if isempty(line) || startsWith(line, 'Freq')
        continue;
    end
    
    % Identifica o início de um novo bloco de varredura (Step)
    if startsWith(line, 'Step')
        % Salva a curva anterior (se houver) no struct
        if ~isempty(current_freqs)
            curves{end+1} = struct('label', current_label, 'freqs', current_freqs, 'mags', current_mags);
            current_freqs = []; 
            current_mags = [];
        end
        
        % Extrai qualquer parâmetro (Rf, Cf, temp, etc.) escrito na linha
        str_info = extractAfter(line, 'Step Information:');
        if contains(str_info, '(Run:')
            str_info = extractBefore(str_info, '(Run:');
        end
        current_label = strtrim(str_info);
        continue;
    end
    
    % Extrai os números de Frequência e Magnitude em dB
    nums = str2double(regexp(line, '[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?', 'match'));
    
    if length(nums) >= 2
        current_freqs(end+1) = nums(1);
        current_mags(end+1) = nums(2);
    end
end

% Salva a última curva processada após o fim do loop
if ~isempty(current_freqs)
    curves{end+1} = struct('label', current_label, 'freqs', current_freqs, 'mags', current_mags);
end

% --- FASE 2: PLOTAGEM DOS DADOS (MATRIZ EXPLÍCITA) ---
figure('Name', 'Bode Plot - TIA', 'Color', 'w');
hold on;
grid on;

num_curves = length(curves);

% Matriz explícita com as 7 cores padrão do MATLAB (Trio RGB de 0 a 1)
default_colors = [
    0.0000, 0.4470, 0.7410; % 1. Azul
    0.8500, 0.3250, 0.0980; % 2. Laranja
    0.9290, 0.6940, 0.1250; % 3. Amarelo
    0.4940, 0.1840, 0.5560; % 4. Roxo
    0.4660, 0.6740, 0.1880; % 5. Verde
    0.3010, 0.7450, 0.9330; % 6. Ciano
    0.6350, 0.0780, 0.1840  % 7. Bordô
];

% Define 4 estilos de linha diferentes para criar 28 combinações únicas
line_styles = {'-', '--', '-.', ':'}; 

for i = 1:num_curves
    % Lógica de ciclagem: garante que a cor e o estilo girem sem dar erro
    color_idx = mod(i-1, 7) + 1; 
    style_idx = mod(floor((i-1)/7), length(line_styles)) + 1; 
    
    % Protege underscores para não virarem subscritos na legenda
    safe_label = strrep(curves{i}.label, '_', '\_'); 
    
    % Plota a curva chamando os vetores da struct
    plot(curves{i}.freqs, curves{i}.mags, ...
        'DisplayName', safe_label, ...
        'LineWidth', 1.5, ...
        'Color', default_colors(color_idx, :), ...
        'LineStyle', line_styles{style_idx});
end

% --- FASE 3: FORMATAÇÃO VISUAL AVANÇADA ---
set(gca, 'XScale', 'log'); 
set(gca, 'FontSize', 11, 'FontName', 'Times New Roman');

xlabel('Frequência (Hz)', 'FontWeight', 'bold');
ylabel('Magnitude (dB)', 'FontWeight', 'bold');
title('Resposta em Frequência - Amplificador de Transimpedância', 'FontWeight', 'bold');

% Limites do eixo X focados no objetivo do projeto (até 100 MHz)
xlim([1e3 100e6]); 

% Legenda configurada para o lado de fora, evitando cobrir os dados
lgd = legend('show', 'Location', 'eastoutside');
lgd.Box = 'off';

hold off;