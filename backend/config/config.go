package config

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"text/template"

	"gopkg.in/yaml.v3"
)

// ToneConfig トーン設定全体の構造
type ToneConfig struct {
	SystemRole string          `yaml:"system_role"`
	AIModel    AIModelConfig   `yaml:"ai_model"`
	Tones      map[string]Tone `yaml:"tones"`
}

// AIModelConfig AIモデルの設定
type AIModelConfig struct {
	Name      string `yaml:"name"`
	MaxTokens int    `yaml:"max_tokens"`
}

// Tone 個別トーンの設定
type Tone struct {
	DisplayName         string   `yaml:"display_name"`
	Description         string   `yaml:"description"`
	Characteristics     []string `yaml:"characteristics"`
	InstructionTemplate string   `yaml:"instruction_template"`
}

// PromptData テンプレート実行用のデータ構造
type PromptData struct {
	Characteristics []string
	OriginalText    string
}

var toneConfig *ToneConfig

// LoadToneConfig YAML設定ファイルを読み込み
func LoadToneConfig() (*ToneConfig, error) {
	if toneConfig != nil {
		return toneConfig, nil
	}

	// 設定ファイルのパスを取得
	configPath := getConfigPath()
	
	// ファイル読み込み
	data, err := os.ReadFile(configPath)
	if err != nil {
		return nil, fmt.Errorf("設定ファイルの読み込みに失敗: %w", err)
	}

	// YAML パース
	var config ToneConfig
	if err := yaml.Unmarshal(data, &config); err != nil {
		return nil, fmt.Errorf("YAML設定の解析に失敗: %w", err)
	}

	toneConfig = &config
	return toneConfig, nil
}

// GetPrompt 指定されたトーンのプロンプトを生成
func (tc *ToneConfig) GetPrompt(toneName, originalText string) (string, error) {
	tone, exists := tc.Tones[toneName]
	if !exists {
		return "", fmt.Errorf("サポートされていないトーンです: %s", toneName)
	}

	// テンプレートを作成
	tmpl, err := template.New("prompt").Parse(tone.InstructionTemplate)
	if err != nil {
		return "", fmt.Errorf("プロンプトテンプレートの解析エラー: %w", err)
	}

	// テンプレート実行用データ
	data := PromptData{
		Characteristics: tone.Characteristics,
		OriginalText:    originalText,
	}

	// テンプレート実行
	var result strings.Builder
	if err := tmpl.Execute(&result, data); err != nil {
		return "", fmt.Errorf("プロンプトテンプレートの実行エラー: %w", err)
	}

	// システムロールを追加して完全なプロンプトを作成
	fullPrompt := tc.SystemRole + "\n\n" + result.String()
	
	return fullPrompt, nil
}

// GetAvailableTones 利用可能なトーン一覧を取得
func (tc *ToneConfig) GetAvailableTones() map[string]string {
	tones := make(map[string]string)
	for key, tone := range tc.Tones {
		tones[key] = tone.DisplayName
	}
	return tones
}

// GetAIModelConfig AIモデル設定を取得
func (tc *ToneConfig) GetAIModelConfig() AIModelConfig {
	return tc.AIModel
}

// getConfigPath 設定ファイルのパスを取得
func getConfigPath() string {
	// 環境変数から設定ファイルパスを取得（カスタマイズ用）
	if customPath := os.Getenv("TONE_CONFIG_PATH"); customPath != "" {
		return customPath
	}
	
	// デフォルトパス: バイナリと同じディレクトリのconfig/tone_prompts.yaml
	execPath, err := os.Executable()
	if err != nil {
		// フォールバック: 現在のディレクトリ
		return filepath.Join("config", "tone_prompts.yaml")
	}
	
	execDir := filepath.Dir(execPath)
	return filepath.Join(execDir, "config", "tone_prompts.yaml")
}

// ReloadConfig 設定ファイルを再読み込み（開発・チューニング用）
func ReloadConfig() error {
	toneConfig = nil
	_, err := LoadToneConfig()
	return err
}