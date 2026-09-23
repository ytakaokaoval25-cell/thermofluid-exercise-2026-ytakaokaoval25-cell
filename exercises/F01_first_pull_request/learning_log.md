# F01 学習ログ

## 予想と結果

- 変更した箇所：
  `exercises/F01_first_pull_request/run.jl` の `student_greeting` を実装し、
  `exercises/F01_first_pull_request/tests.jl` に自作テストを追加した。

- 期待した表示と実際の表示：
  GitHubユーザー名 `ytakaokaoval25-cell` を入力したとき、
  `Hello, ytakaokaoval25-cell!` と表示されることを期待した。
  実際に同じ文字列が表示された。

## 自分のテスト

- 自分で選んだ入力と期待値（実名は不要）：
  入力：`"ytakaokaoval25-cell"`
  期待値：`"Hello, ytakaokaoval25-cell!"`

- 保証すること・保証しないこと：
  自作テストでは、通常の文字列を入力したときに
  `Hello, <name>!` の形式で正しい文字列が返ることを確認する。
  前後の空白除去と空文字入力時の例外については、配布済み必須テストで確認されている。

- 実行コマンドと結果：
  `julia --project=. exercises/F01_first_pull_request/run.jl "ytakaokaoval25-cell"`
  を実行し、`Hello, ytakaokaoval25-cell!` が表示された。

  また、
  `julia --project=. -e 'using Pkg; Pkg.test()'`
  を実行し、F01のテストは3件すべて成功し、プロジェクト全体のテストも成功した。

## つまずきと判断

- つまずき、その対処と理由：
  Juliaのテストコードを誤ってターミナルへ直接入力してしまい、
  `dquote>` の入力待ち状態になった。
  `Control + C` で入力を中断し、テストコードはターミナルではなく
  `tests.jl` に記述するものだと確認した。

  また、自作テストを一度 `run.jl` に記述してしまったため、
  `run.jl` には実装のみを残し、自作テストは `tests.jl` へ移動した。

- 配布済み必須テストが保証することと、自作テストの入力・期待値を選んだ理由：
  配布済み必須テストは、入力前後の空白が `strip` により除去されることと、
  空白のみの入力に対して `ArgumentError` が発生することを保証している。
  自作テストではそれらと重複しない通常入力のケースを確認するため、
  GitHubユーザー名 `ytakaokaoval25-cell` を選び、
  `Hello, ytakaokaoval25-cell!` が返ることを期待値とした。

## AI利用・出典

- 依頼内容：
  ChatGPTとGitHub Copilotを利用した。
  環境構築、Git/GitHub操作、F01の進め方の確認をChatGPTに依頼した。
  GitHub Copilotには、F01の実装、自作テストの修正、
  ローカルテストの実行、`git diff` による変更確認を依頼した。

- 重要な提案：
  `student_greeting` で `strip` 後の名前を用いて
  `Hello, <name>!` を返すこと、
  自作テストを `tests.jl` に追加すること、
  実装後にプロジェクト全体のテストを実行することが提案された。

- 採用・修正・却下と理由：
  `student_greeting` の実装方法と自作テスト追加の方針は、
  課題仕様と一致することを確認して採用した。
  一度自作テストを `run.jl` に入れてしまった点は不適切だったため、
  `tests.jl` に移動するよう修正した。
  また、commit・push・PRは変更内容とテスト結果を自分で確認してから行うことにした。

- 外部素材の出典、変更点、利用条件（なければ「なし」）：
  なし。

## 理解度チェック・LETUS提出

- 対応する授業ID：
  F01（授業ID 01）

- LETUS提出日：
  2026/09/23

- 提出済み確認：
  提出済み

- 理解できた点：
  Gitでは `main` に直接実装するのではなく、課題用branchを作成し、
  実装・テスト・diff確認・commit・pushを行った後、
  pull requestを通して `main` にmergeする流れを理解した。
  また、Juliaコードとテストコードを別ファイルに分けて、
  `Pkg.test()` で動作を確認する方法を理解した。

- 残った疑問：
  なし。

- 対話全文はLETUSへ提出し，このリポジトリには含めていない：
  はい
