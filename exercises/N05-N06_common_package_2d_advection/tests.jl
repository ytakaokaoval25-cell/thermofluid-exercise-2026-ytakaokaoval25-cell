# N05/N06: 提供済みの必須テスト → 受講生が編集する自作テスト。必須の期待値は保持します。

using Test, ThermofluidExercise
@testset "N05 共通API" begin
    @test ThermofluidExercise.periodic_left_index(1, 4) == 4
    @test ThermofluidExercise.periodic_right_index(4, 4) == 1
    @test ThermofluidExercise.linear_flux(2., 3.) == 6.
    @test ThermofluidExercise.burgers_flux(-2.) == 2.
    @test ThermofluidExercise.fit_timestep(0.3, 1.) == (steps = 4, dt = 0.25)
end
@testset "N06 配布済み数値テスト" begin
    old = Float64[1 2 4 3; 5 7 6 8; 9 10 12 11]
    saved = copy(old)
    new = similar(old)
    N = ThermofluidExercise.N06
    @test N.advection_step!(new, old, 0.1, 0.5, 0.25; cx = 1., cy = 0.75)===new
    @test new≈[3.2 3.3 5.0 4.9; 5.1 5.4 5.9 6.4; 8.8 9.1 10.2 10.7] atol = 1e-13
    @test old == saved
    @test N.stable_timestep(1., 0.75, 0.5, 0.25)≈0.16
    @test_throws ArgumentError N.advection_step!(old, old, 0.1, 0.5, 0.25)
    @test_throws ArgumentError N.advection_step!(
        new,
        old,
        0.21,
        0.5,
        0.25;
        cx = 1.,
        cy = 0.75,
    )
    N.advection_step!(new, fill(2., 3, 4), 0.1, 0.5, 0.25)
    @test new == fill(2., 3, 4)
    N.advection_step!(new, old, 0.1, 0.5, 0.25; cx = 0., cy = 0.)
    @test new == old
    N.advection_step!(new, old, 0.1, 0.5, 0.25; cx = 0., cy = 0.75)
    @test new≈[1.6 1.7 3.4 3.3; 5.9 6.4 6.3 7.4; 9.6 9.7 11.4 11.3]
end
@testset "N06 自作: 複数ステップの保存量" begin
    old = Float64[1 2 5 4; 7 3 8 6; 11 10 9 12; 13 16 14 15; 20 17 19 18]
    new = similar(old)
    initial_sum = sum(old)
    for _ in 1:25
        ThermofluidExercise.N06.advection_step!(
            new, old, 0.05, 0.4, 0.25; cx = 1.0, cy = 0.5,
        )
        old, new = new, old
    end
    tolerance = 100eps(Float64) * max(1.0, abs(initial_sum)) * 25
    @test isapprox(sum(old), initial_sum; atol = tolerance, rtol = 0)
end
@testset "N06 自作: 3格子の解析解誤差と収束" begin
    u0(x, y) = 1 + 0.2sin(pi * x) + 0.3cos(2pi * y) + 0.1sin(pi * x + 2pi * y)
    exact(x, y, t) = [u0(mod(xi - t, 2.0), mod(yj - 0.5t, 1.0)) for xi in x, yj in y]
    errors = Float64[]
    for (nx, ny) in ((40, 30), (80, 60), (160, 120))
        dx, dy = 2 / nx, 1 / ny
        x, y = collect((0:(nx - 1)) .* dx), collect((0:(ny - 1)) .* dy)
        old = exact(x, y, 0.0)
        new = similar(old)
        dt_max = ThermofluidExercise.N06.stable_timestep(1.0, 0.5, dx, dy)
        steps, dt = ThermofluidExercise.fit_timestep(dt_max, 1.0)
        for _ in 1:steps
            ThermofluidExercise.N06.advection_step!(new, old, dt, dx, dy)
            old, new = new, old
        end
        push!(errors, sqrt(sum(abs2, old - exact(x, y, 1.0)) / length(old)))
    end
    orders = log2.(errors[1:2] ./ errors[2:3])
    @test all(diff(errors) .< 0)
    @test all(0.8 .<= orders .<= 1.2)
end
module N0506OutputChecks
include("provided_support.jl")
include("N05.jl")
end
@testset "N05-N06 保存結果と出自" begin
    @test N0506OutputChecks.check_complete()
    baseline = joinpath(@__DIR__, "results", "N05", "baseline.toml")
    regression = joinpath(@__DIR__, "results", "N05", "regression.toml")
    @test isfile(baseline) && isfile(regression)
    report = N0506OutputChecks.TOML.parsefile(regression)
    @test report["baseline_sha256"] == N0506OutputChecks.file_sha(baseline)
    @test report["code_sha256"] == N0506OutputChecks.N05Regression.code_hashes(
        normpath(joinpath(@__DIR__, "..", "..")),
    )
end
