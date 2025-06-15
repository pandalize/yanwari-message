# yanwari-message

# **やんわり伝言サービス 要件定義書（v0.9）**

## 0. ドキュメント目的
- 3 名チームが **Roo Code** 上で共同開発する際の共通仕様書  
- 500 行以内・Markdown 形式  
- 以降の設計／実装／レビュー／テストの基準とする  

---

## 1. プロダクト概要
| 項目 | 内容 |
| --- | --- |
| プロダクト名 | **やんわり伝言サービス** |
| 主な価値 | 上司⇔部下・恋人など「気まずい用件」を AI で優しく伝える |
| 対応プラットフォーム | Web (SPA) → PWA → iOS/Android (Capacitor または Quasar) |
| ビジネスモデル | SaaS 月額課金 (SMB → Enterprise) |
| 想定ユーザ規模 | 初期 500 MAU → 2 年後 50 000 MAU |

---

## 2. MVP スコープ

| # | 機能 | 優先度 |
| - | ---- | ---- |
| F-01 | メール・パスワード認証 / JWT 発行 | ★★★ |
| F-02 | 下書き作成 + トーン変換 (gentle/constructive/casual) | ★★★ |
| F-03 | 送信スケジュール設定 (ISO8601) | ★★★ |
| F-04 | 下書き／送信履歴一覧・検索 | ★★☆ |
| F-05 | 返信の感情トーン自動判定 **(後続リリース)** | ☆☆☆ |
| F-06 | Google/iCloud カレンダー連携 **(後続)** | ☆☆☆ |

---

## 3. 非機能要件

| 分類 | 要件 |
| --- | --- |
| 性能 | 99 パーセンタイル API レイテンシ ≤ 300 ms（OpenAI 呼び出し含まず） |
| 可用性 | 月間稼働率 99.5 % |
| セキュリティ | JWT 失効／HTTPS／OWASP Top 10 準拠 |
| スケーラビリティ | MongoDB Atlas M2→M10 へスケールアップで 5 万 MAU まで無停止 |
| 国際化 | UTC+TZ 変換, i18n 基盤のみ実装（日本語 UI 優先） |
| 監視 | Prometheus + Grafana Cloud＋Sentry (Front) |

---

## 4. アーキテクチャ

```mermaid
flowchart LR
  subgraph Frontend
    A[Vue 3 SPA]
  end
  subgraph Backend
    B(Go Gin API)
    C(OpenAI Client)
    D(MongoDB Atlas)
    B --> D
    B --> C
  end
  A -- JWT/HTTPS --> B
````

### 4.1 技術スタック

| レイヤ    | 採用技術                                        |
| ------ | ------------------------------------------- |
| フロント   | Vue 3 + Vite + Pinia + Vue Router           |
| バックエンド | Go 1.22 + Gin + Wire (DI)                   |
| DB     | MongoDB Atlas Shared (M2)                   |
| AI 連携  | OpenAI Chat Completions v1                  |
| 認証     | Argon2 + JWT (access 15 min / refresh 14 d) |
| インフラ   | AWS (ALB/ECS Fargate) + CloudFront          |
| CI/CD  | GitHub Actions → ECR → ECS (blue/green)     |

---

## 5. データモデル（抜粋）

### 5.1 `users`

| フィールド          | 型               | 備考               |
| -------------- | --------------- | ---------------- |
| `_id`          | ObjectId        | PK               |
| `email`        | string (unique) |                  |
| `passwordHash` | string          | Argon2           |
| `timezone`     | string          | ex: "Asia/Tokyo" |

### 5.2 `drafts`

| name              | type     | note         |
| ----------------- | -------- | ------------ |
| `_id`             | ObjectId |              |
| `userId`          | ObjectId | FK(users)    |
| `originalText`    | string   |              |
| `tonePreset`      | string   | "gentle" 等   |
| `transformedText` | string   | AI 返却        |
| `status`          | enum     | pending/sent |

---

## 6. API 仕様（Version = v1）

### 6.1 認証

```
POST /api/v1/auth/login
req: { email, password }
res: { accessToken, refreshToken, expiresIn }
```

### 6.2 下書き作成

```
POST /api/v1/drafts
req: { originalText, tonePreset, sendAt?, targetUserId? }
res: { draftId, transformedText }
```

### 6.3 下書き取得

```
GET /api/v1/drafts/:id
```

### 6.4 送信スケジュール

```
POST /api/v1/schedules
req: { draftId, sendAt }
```

---

## 7. プロンプトテンプレート

```text
System: あなたはプロのコミュニケーションコーチです。
Instruction: 次の文章を <tone> トーンで書き換えて下さい。
Output: 本文のみ、日本語。
User: {{originalText}}
```

---

## 8. Git 運用方針（GitFlow＋Roo Code）

| ブランチ           | 用途        | マージ先         | 保護設定          |
| -------------- | --------- | ------------ | ------------- |
| **main**       | 本番デプロイタグ用 | -            | Force-push 禁止 |
| **develop**    | 次リリース統合   | main         | PR 必須         |
| **feature/\*** | 機能単位      | develop      | ―             |
| **release/\*** | リリース準備    | develop→main | CI: e2e 実行    |
| **hotfix/\***  | 本番緊急修正    | main→develop | ―             |

* **Roo Code** 上で feature ブランチを共同編集 → PR 作成
* CI: `go vet`, `go test`, `npm run test`, `docker build`
* main へマージ時に GitHub Actions が `prod` ECS へ自動デプロイ

---

## 9. 3 名チーム体制

| Role    | 担当              | 主ツール                       |
| ------- | --------------- | -------------------------- |
| FE Lead | Vue3 開発・デザイン調整  | Roo Code + Figma           |
| BE Lead | API／AI 連携・DB 設計 | Roo Code + Atlas UI        |
| DevOps  | CI/CD・IaC・監視    | Terraform + GitHub Actions |

共同レビューは Roo Code の Live Share（ペアコーディング）機能で実施。
毎日 15 min デイリー。金曜にスプリントレビュー。

---

## 10. リリースロードマップ（概略）

| Sprint (2w) | 目標                |
| ----------- | ----------------- |
| #1          | 環境構築・ログイン API     |
| #2          | 下書き作成 + OpenAI 連携 |
| #3          | スケジュール送信・履歴一覧     |
| #4          | ステージング負荷試験・βテスト   |
| #5          | 本番リリース（v1.0）      |

---

## 11. リスク & 対策

| リスク          | 対策                                |
| ------------ | --------------------------------- |
| OpenAI レート制限 | バックオフ + キューイング                    |
| 個人情報リーク      | 送信文から PII を検出しない指針文書を整備           |
| Mongo スキーマ肥大 | `mongoose-like` バリデーション実装 / 型自動生成 |

---

## 12. 参考リンク

* OpenAI API v1 docs
* Gin Official Docs
* MongoDB Atlas CLI / Provider
* Roo Code Collaboration Guide

---

### 以上

```
```
