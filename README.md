[![Flutter CI](https://github.com/susatthi/flutter-sample-isar/actions/workflows/flutter_ci.yaml/badge.svg)](https://github.com/susatthi/flutter-sample-isar/actions/workflows/flutter_ci.yaml)
[![codecov](https://codecov.io/gh/susatthi/flutter-sample-isar/branch/main/graph/badge.svg?token=ZGF5SOBBSM)](https://codecov.io/gh/susatthi/flutter-sample-isar)
<a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-purple" alt="MIT"></a>

# Isar Database サンプルアプリ

[Isar Database](https://pub.dev/packages/isar) のサンプルのメモアプリ

![デモ](https://user-images.githubusercontent.com/13707135/172751546-4b8b5e0a-ab36-404e-adeb-63742da841fd.gif)

## アプリの概要

- メモを追加、編集、削除ができる
- メモの一覧を表示できる
- メモをカテゴリにわけて管理できる
- カテゴリはあらかじめ用意しておく（仕事、プライベート、その他の３種類とする）

## ポイント

- Isar のバージョンは ^3.0.0-dev.0
- IsarLink を使用して Collection を Link （テーブルのリレーション）
- JSON ファイルの初期データ（ Seed ）を DB に書き込み
- 単体テスト／ Widget テストを実装
- GitHub Actions の CI による自動テスト
- サポートするプラットフォーム
  - iOS / Android / Web / macOS / Windows

## ライセンス

MIT
