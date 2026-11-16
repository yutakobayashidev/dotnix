# ActivityLog

[ymotongpoo/activitylog](https://github.com/ymotongpoo/activitylog) の Android
アプリが送るアクティビティ（前面アプリ、画面のオン/オフ、ロック解除、Chromium 系
ブラウザの URL）を、B450M-Pro4 の既存 Grafana スタック（VictoriaMetrics / Loki /
Tempo）で受けて可視化する。デスクトップ版エージェントは対象外。

## データの流れ

```
Android アプリ ──OTLP/HTTP (HTTPS + Basic)──▶ Traefik ──▶ Alloy (127.0.0.1:4316)
                                                     ├─ metrics ─▶ VictoriaMetrics
                                                     ├─ logs    ─▶ Loki
                                                     └─ traces  ─▶ Tempo
```

- **エンドポイント**: `https://otlp.home.yutakobayashi.com`。Tailscale のみ到達
  （公開していない）。端末は Tailscale に接続している必要がある。
- **認証**: HTTP Basic。ユーザー名 `activitylog`（アプリの Instance ID 欄に同じ
  値を入れる）、パスワードはトークン（別途共有）。Traefik の `basicAuth`
  ミドルウェアが検証する。
- **Alloy**: `otelcol.receiver.otlp` が OTLP/HTTP を受け、cumulative の
  メトリクスを `prometheus.remote_write` で VictoriaMetrics へ、ログを Loki の
  OTLP エンドポイント（`/otlp`）、トレースを Tempo へ送る。activitylog の
  メトリクスはすでに cumulative なので `deltatocumulative` を通さず、また
  プライバシー処理はアプリ側で済むためスクラブもしない。
- **ダッシュボード**: [activitylog overview](https://grafana.home.yutakobayashi.com/d/activitylog-overview/activitylog)
  と [Android](https://grafana.home.yutakobayashi.com/d/activitylog-android/android)。

## Android アプリのセットアップ（手動）

APK はリポジトリの Releases に置かれていないため、手元でビルドしてサイドロードする。

1. **ビルド**（JDK 21 + Android SDK platform 36 / build-tools 35 以上が必要）:
   ```sh
   git clone https://github.com/ymotongpoo/activitylog
   cd activitylog/android
   ./gradlew assembleDebug
   ```
   APK は `app/build/outputs/apk/debug/app-debug.apk` にできる。
2. **インストール**: 端末の開発者向けオプションで USB デバッグを有効にし、
   PC につないで `adb install -r app/build/outputs/apk/debug/app-debug.apk`。
3. **接続先を設定**: アプリの設定画面で保存する（先に設定してから権限を付与する）。
   - OTLP endpoint: `https://otlp.home.yutakobayashi.com`
   - Instance ID: `activitylog`
   - Token: セットアップ時に共有したトークン
4. **権限を付与**:
   - 使用状況へのアクセス（Usage Access）: これがないと何も収集しない。
   - ユーザー補助（Accessibility）: Chrome の URL を取る場合のみ。
   - Android 13 以降はサイドロードしたアプリの「制限付き設定」を許可しないと
     上記をオンにできない。拒否された後、アプリ情報のメニュー（⋮）→
     「制限付き設定を許可」→ 指紋/PIN で確認してから、もう一度オンにする。
5. **確認**: 「Send now」で即時送信し、Grafana の Explore で
   `{service_name="activitylog-android"}`（Loki）や `activity_time_seconds_total`
   （Prometheus）を確認する。

## トークンのローテーション

Basic 認証のパスワードは bcrypt ハッシュとして `authHash` に保持している
（一方向ハッシュなので Git に置いても安全。平文トークンはコミットしない）。

```sh
mkpasswd -m bcrypt "$NEW_TOKEN"   # 新しいハッシュを得る
```

`systems/nixos/B450M-Pro4/default.nix` の `my.services.activitylog.authHash` を
置き換えてコミット・デプロイし、アプリの Token 欄も更新する。トークンを失くした
場合も同じ手順で再発行できる（既存の未送信キューはアプリ側に残る）。

## 検証

1. デプロイ後、`alloy` サービスがアクティブで、`/targets` に activitylog の
   レシーバーが無いこと（Alloy はレシーバーのため targets には出ない）を確認。
2. アプリで「Send now」を実行し、Grafana Explore の Loki で
   `{service_name="activitylog-android"}`、Prometheus で
   `activity_time_seconds_total{job="activitylog/activitylog-android"}` を確認。
3. ダッシュボードに端末（instance ラベル）が現れることを確認する。
