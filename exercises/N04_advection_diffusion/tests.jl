# 必須テストは提供済みの期待値で確認します。末尾の自作テストだけを受講生が編集します。
# 入力の準備 → 独立した期待値との比較 → 入力保持・不正入力の確認の順に読みます。

using Test
if !isdefined(Main, :N04AdvectionDiffusion)
    include(joinpath(@__DIR__, "run.jl"))
end
import .N04AdvectionDiffusion
const N04 = N04AdvectionDiffusion
N04.validate_model(N04.SELECTED_MODEL)
@testset "N04 必須テスト" begin
    model = N04.SELECTED_MODEL
    @testset "非対称1ステップ・周期端・旧配列不変" begin
        old = [1., 2., 4., 3.]
        saved = copy(old)
        new = similar(old)
        expected = model == :linear ? [1.26, 1.92, 3.74, 3.08] : [1.46, 1.87, 3.34, 3.33]
        @test N04.advection_diffusion_step!(new, old, 0.1, 1., 0.2) === new
        @test new ≈ expected atol = 1e-14
        @test old == saved
    end
    @testset "定数場と周期積分" begin
        old = fill(1.7, 5)
        new = similar(old)
        N04.advection_diffusion_step!(new, old, 0.1, 1., 0.2)
        @test new ≈ old
        @test N04.conserved_integral([1., 2., 4., 3.], 0.5) == 5.
    end
    @testset "移流・拡散をゼロにした極限" begin
        old = [1., 2., 4., 3.]
        new = similar(old)
        N04.advection_diffusion_step!(new, old, 0.1, 1., 0.2; advection = false)
        @test new ≈ [1.06, 2.02, 3.94, 2.98]
        N04.advection_diffusion_step!(new, old, 0.1, 1., 0.)
        @test new ≈ (model == :linear ? [1.2, 1.9, 3.8, 3.1] : [1.4, 1.85, 3.4, 3.35])
    end
    @testset "合成刻み・最終時刻・標準安定性" begin
        @test N04.stable_timestep(2., 0.5, 0.1) ≈ 1 / 6
        r = N04.simulate()
        @test r.steps * r.dt ≈ r.t_final == 1.
        @test r.max_stability_number <= 0.8 + 1e-12
        @test all(isfinite, r.u) && 1 - 1e-12 <= r.minimum <= r.maximum <= 2 + 1e-12
    end
end
@testset "N04 自作テスト" begin
    @testset "周期積分の複数ステップ保存" begin
        u_initial = [1.1, 1.8, 1.3, 2.2, 1.5, 2.0, 1.4]
        u_old = copy(u_initial)
        u_new = similar(u_old)
        dx, dt, diffusivity = 1.0, 0.1, 0.2
        steps = 30
        initial_integral = dx * sum(u_initial)

        for _ in 1:steps
            N04.advection_diffusion_step!(u_new, u_old, dt, dx, diffusivity)
            u_old, u_new = u_new, u_old
        end

        atol = 100eps(Float64) * length(u_initial) * steps * maximum(abs, u_initial)
        @test isapprox(dx * sum(u_old), initial_integral; atol, rtol=0)
    end

    @testset "線形モデルの解析解と格子収束" begin
        grids = (40, 80, 160)
        runs = [N04.simulate(; nx, initial=:mode) for nx in grids]
        errors = [maximum(abs.(
            r.u - N04.analytic_solution(
                r.x, r.t_final;
                model=N04.SELECTED_MODEL,
                diffusivity=r.diffusivity,
                speed=r.speed,
            )
        )) for r in runs]
        orders = log2.(errors[1:2] ./ errors[2:3])

        @test errors[1] > errors[2] > errors[3] > 0
        @test all(0.8 .< orders .< 1.2)
    end
end
