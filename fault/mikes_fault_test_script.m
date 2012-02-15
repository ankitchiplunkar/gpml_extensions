clear
close all
addpath(genpath('~/Code/gpml-matlab-v3.1-2010-09-27/'))
load(['quasars.mat']);

inds = (1:10:500);

train_x = wavelengths(inds)';

train_y = data(end, :);
train_y = train_y(inds)';

test_x = wavelengths(:);

fault_shape      = linspace(-1, 1).^2 - 1;
fault_length_scale = log(20);
fault_output_scale = log(30);
fault_start_time = 1215;
fault_end_time   = 1240;

length_scale = log(5);
output_scale = log(1);

noise_scale = log(1);

inference_method = @infExactFault;
mean_function = @meanConst;
covariance_function = @covSEiso;
fault_covariance_function = {@covDrift, {@covSEiso}};
likelihood = @likGauss;

% NB: this formulation assumes A is always a diagonal matrix with diagonal
% given by the a function
a_function = @meanOne;
b_function = @meanZero;

hyperparameters.mean = mean(train_y);
hyperparameters.cov = ...
     [length_scale; output_scale];
hyperparameters.lik = noise_scale;

hyperparameters.a = [];
hyperparameters.b = [];
hyperparameters.fault_covariance_function =...
    [fault_start_time; fault_end_time; fault_length_scale; fault_output_scale];

[hyperparameters inference_method mean_function covariance_function ...
 likelihood a_function b_function] = ...
    check_gp_fault_arguments(hyperparameters, inference_method, ...
                             mean_function, covariance_function, ...
                             likelihood, a_function, b_function, ...
                             fault_covariance_function, train_x);

[output_means output_variances latent_means latent_variances fault_means fault_variances] = ...
    gp_fault(hyperparameters, inference_method, mean_function, ...
             covariance_function, likelihood, a_function, b_function, ...
             fault_covariance_function, ...
             train_x, train_y, test_x);

make_gp_plot(test_x, latent_means, sqrt(latent_variances), train_x, ...
             train_y, [min(wavelengths) max(wavelengths) 0 35], 7, ...
             'wavelength', 'energy', 'SouthWest', 25, 6);
title('latent function -- good');

make_gp_plot(test_x, output_means, sqrt(output_variances), train_x, ...
             train_y, [min(wavelengths) max(wavelengths) 0 35], 7, ...
             'wavelength', 'energy', 'SouthWest', 25, 6);
title('outputs');

make_gp_plot(test_x, fault_means, sqrt(fault_variances), train_x, ...
             train_y, [min(wavelengths) max(wavelengths) 0 35], 7, ...
             'wavelength', 'energy', 'SouthWest', 25, 6);
title('fault contribution');

negative_log_likelihood = ...
    gp_fault(hyperparameters, inference_method, mean_function, ...
             covariance_function, likelihood, a_function, b_function, ...
             fault_covariance_function, train_x, train_y);

disp(['likelihood: ' num2str(-negative_log_likelihood)]);