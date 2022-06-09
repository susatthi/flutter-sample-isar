# flutter_sample_isar

[Isar Database](https://pub.dev/packages/isar) のサンプルのメモアプリ

![デモ](https://user-images.githubusercontent.com/13707135/172751546-4b8b5e0a-ab36-404e-adeb-63742da841fd.gif)

## アプリの概要

- メモを追加、編集、削除ができる
- メモの一覧を表示できる
- メモをカテゴリにわけて管理できる
- カテゴリはあらかじめ用意しておく（仕事、プライベート、その他の３種類とする）

## ポイント

- Isar のバージョンは ^3.0.0-dev.0
- テーブルのリレーション（CollectionのLink）
- JSON ファイルの初期データ（ Seed ）を DB に書き込み
- 単体テスト／ Widget テストを実装
