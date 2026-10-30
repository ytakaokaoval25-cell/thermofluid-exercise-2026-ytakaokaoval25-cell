# 必須テストは、数値更新・境界条件・熱量・標準計算を順に確認します。
# 末尾の「自作テスト」では、確認したい性質と許容誤差を自分で決めます。

using Test

# 単独実行時は読み込み、Pkg.test などで読込済みなら既存のモジュールを使う。
if !isdefined(Main,:N03Diffusion)
    include(joinpath(@__DIR__, "run.jl"))
end
import .N03Diffusion

@testset "N03 必須テスト" begin
    @testset "小配列1ステップと旧配列不変" begin
        # 非対称な配列を用意し、更新前の値を別の配列に保存する。
        old = [1., 2., 4., 3.]
        saved = copy(old)
        new = similar(old)

        # 新配列の値と、旧配列が変更されていないことを確認する。
        N03Diffusion.diffusion_step!(new, old, 0.25, 1., 1.; boundary=:insulated)
        @test new == [1.5, 2.25, 3.25, 3.5]
        @test old == saved
    end

    @testset "定数場と固定端" begin
        # 各境界条件と両立する定数場は、1ステップ後も変化しない。
        for (boundary, value) in ((:insulated, 0.7), (:fixed, 0.))
            old = fill(value, 5)
            new = similar(old)
            N03Diffusion.diffusion_step!(new, old, 0.2, 1., 1.; boundary)
            @test new ≈ old
        end

        # 既定の固定温度条件では、更新後の両端が0になる。
        old = [1., 2., 4., 3.]
        new = similar(old)
        N03Diffusion.diffusion_step!(new, old, 0.25, 1., 1.)
        @test new == [0., 2.25, 3.25, 0.]
    end

    @testset "台形則の熱量" begin
        # 断熱条件の1ステップ更新前後で、端点の重みを含む熱量を比較する。
        @test N03Diffusion.thermal_content([1., 2., 4., 3.], 1.) == 8.
        @test N03Diffusion.thermal_content([1.5, 2.25, 3.25, 3.5], 1.) == 8.
    end

    @testset "標準計算の安定性" begin
        for boundary in (:fixed, :insulated)
            # 各境界条件で、既定の終了時刻まで計算する。
            r = N03Diffusion.simulate(; boundary)

            # 終了時刻・安定条件・有限性・温度範囲を確認する。
            @test r.steps * r.dt ≈ r.t_final == 1.
            @test 0 < r.fo <= 0.5
            @test all(isfinite, r.u)
            @test -1e-13 <= r.minimum <= r.maximum <= 1 + 1e-13
        end
    end
end

@testset "N03 自作テスト" begin
    @testset "断熱境界の熱量保存" begin
        # 端点も互いに異なる非対称な7点配列を、安定なr=0.2で25ステップ進める。
        u_initial = [0.3, 1.7, 0.8, 2.4, 1.1, 3.2, 0.6]
        u_old = copy(u_initial)
        u_new = similar(u_old)
        dx, dt, diffusivity = 1.0, 0.2, 1.0
        steps = 25

        # 実装対象のthermal_contentを使わず、テスト側で台形則の初期熱量を求める。
        initial_heat = dx * (
            sum(u_initial[2:end-1]) + (u_initial[1] + u_initial[end]) / 2
        )
        for _ in 1:steps
            N03Diffusion.diffusion_step!(
                u_new, u_old, dt, dx, diffusivity; boundary=:insulated,
            )
            u_old, u_new = u_new, u_old
        end

        # 各点・各ステップの丸め誤差の蓄積に余裕を持たせた絶対許容誤差。
        atol = 100eps(Float64) * length(u_initial) * steps * maximum(abs, u_initial)
        @test isapprox(
            N03Diffusion.thermal_content(u_old, dx), initial_heat; atol, rtol=0,
        )
    end

    @testset "固定温度の解析解と格子収束" begin
        # 同じ時刻・要求Fourier数で格子だけを細かくし、最大絶対誤差を比較する。
        grids = (41, 81, 161)
        runs = [N03Diffusion.simulate(; boundary=:fixed, nx, initial=:mode) for nx in grids]
        errors = [maximum(abs.(
            r.u - N03Diffusion.analytic_solution(
                r.x, r.t_final; boundary=:fixed, diffusivity=r.diffusivity,
            )
        )) for r in runs]
        orders = log2.(errors[1:2] ./ errors[2:3])

        @test errors[1] > errors[2] > errors[3] > 0
        @test all(1.8 .< orders .< 2.2)
    end
end
