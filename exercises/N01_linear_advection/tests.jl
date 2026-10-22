# N01のテスト枠。必須テストと自作テストの両方を受講生が実装します。
# 各TODOで入力と独立した期待値を選び、配列全体・境界・安定性を確認します。

using Test

if !isdefined(Main, :N01LinearAdvection)
    include(joinpath(@__DIR__, "run.jl"))
end

@testset "N01 必須テスト" begin
    # TODO(必須): 座標、base、plateau、区間端を自分で選び、rectangular_initial_conditionが返す配列全体を手計算した期待値と比較する。
    x = [0.0, 0.5, 1.0, 1.5, 2.0]
    @test N01LinearAdvection.rectangular_initial_condition(x) == [1.0, 2.0, 2.0, 1.0, 1.0]

    # TODO(必須): 小さなu_old、移流速度、時間刻み、格子幅を選び、upwind_step!後のu_new配列全体を手計算した期待値と比較する。
    u_old = [1.0, 2.0, 2.0, 1.0, 1.0]
    u_upwind = zeros(5)
    N01LinearAdvection.upwind_step!(u_upwind, u_old, 1.0, 0.5, 1.0)
    @test u_upwind == [1.0, 1.5, 2.0, 1.5, 1.0]

    # TODO(必須): 同じ入力でcentered_step!後のu_new配列全体を手計算した期待値と比較する。風上差分との違いが現れる入力を選ぶ。
    u_centered = zeros(5)
    N01LinearAdvection.centered_step!(u_centered, u_old, 1.0, 0.5, 1.0)
    @test u_centered == [1.0, 1.75, 2.25, 1.25, 1.0]
    @test u_centered != u_upwind

    # TODO(必須): apply_boundary!が左端と右端を課題の境界条件どおりに書き換えることを、配列全体の期待値で確かめる。
    u_boundary = [9.0, 2.0, 3.0, 8.0]
    N01LinearAdvection.apply_boundary!(u_boundary)
    @test u_boundary == [1.0, 2.0, 3.0, 3.0]

    # TODO(必須): simulateで安定な風上差分と不安定な中心差分を同じ条件で計算し、最終値の範囲または振幅から両者の違いを確かめる。条件と判定基準は自分で書く。
    stable = N01LinearAdvection.simulate(; scheme=:upwind, nx=81, c=1.0, cfl=0.5, t_final=0.5)
    unstable = N01LinearAdvection.simulate(; scheme=:centered, nx=81, c=1.0, cfl=0.5, t_final=0.5)
    @test 1.0 <= stable.minimum <= stable.maximum <= 2.0
    @test unstable.minimum < 1.0
    @test unstable.maximum > 2.0
end

@testset "N01 自作テスト" begin
    # TODO(自作): 必須とは異なる初期条件、CFL、格子数、またはAPIの性質を一つ選び、期待する結果を自分で書く。PNG、TOML、ファイルサイズは対象にしない。
    # 旧配列は変更されず、新旧のバッファは独立している（APIの性質）。
    u_old = [1.0, 1.0, 2.0, 1.0, 1.0]
    original = copy(u_old)
    u_new = fill(-99.0, length(u_old))
    @test N01LinearAdvection.upwind_step!(u_new, u_old, 1.0, 0.5, 1.0) === u_new
    @test u_old == original
    @test u_new !== u_old
    @test u_new == [1.0, 1.0, 1.5, 1.5, 1.0]
end
