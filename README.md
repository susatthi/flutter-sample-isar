[![Flutter CI](https://github.com/susatthi/flutter-sample-isar/actions/workflows/flutter_ci.yaml/badge.svg)](https://github.com/susatthi/flutter-sample-isar/actions/workflows/flutter_ci.yaml)
[![codecov](https://codecov.io/gh/susatthi/flutter-sample-isar/branch/main/graph/badge.svg?token=ZGF5SOBBSM)](https://codecov.io/gh/susatthi/flutter-sample-isar)
<a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-purple" alt="MIT"></a>

# Isar Database サンプルアプリ

[Isar Database](https://pub.dev/packages/isar) のサンプルのメモアプリ

![デモ](https://user-images.githubusercontent.com/13707135/172751546-4b8b5e0a-ab36-404e-adeb-63742da841fd.gif)

## アーキテクチャ図

![arch](https://user-images.githubusercontent.com/13707135/173222719-16ece245-e0f9-46e3-99d5-6ba2c178d81d.png)


## アプリの要件

- メモの一覧を更新日時の降順で表示する
- メモを登録、更新、削除ができる
- メモをカテゴリにわけて管理できる
- カテゴリはあらかじめ用意しておく（仕事、プライベート、その他の３種類とする）

## ポイント

- Isar のバージョンは ^3.0.0-dev.0
- IsarLink を使用して Collection を Link するサンプルあり
- JSON ファイルの初期データ（ Seed ）を DB に書き込み
- 単体テスト／ Widget テストを実装
- GitHub Actions の CI による自動テスト
- サポートするプラットフォーム
  - iOS / Android / Web / macOS / Windows
- アーキテクチャ
  - 簡易的なリポジトリパターン（ Widget => Reposiory => Isar ）
  - Isar のサンプルとしてぶれないように Riverpod などの状態管理パッケージはあえて未使用

## ライセンス

MIT
