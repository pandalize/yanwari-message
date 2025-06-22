package config

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"text/template"
	"time"

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

// ScheduleConfig スケジュール設定全体の構造
type ScheduleConfig struct {
	SystemRole        string                       `yaml:"system_role"`
	AIModel           AIModelConfig                `yaml:"ai_model"`
	ScheduleAnalysis  ScheduleAnalysis             `yaml:"schedule_analysis"`
	DefaultSuggestions map[string]DefaultSuggestion `yaml:"default_suggestions"`
	TimeConsiderations map[string]TimeConsideration `yaml:"time_considerations"`
	DayConsiderations  map[string]DayConsideration  `yaml:"day_considerations"`
}

// ScheduleAnalysis スケジュール分析設定
type ScheduleAnalysis struct {
	InstructionTemplate string `yaml:"instruction_template"`
}

// DefaultSuggestion デフォルト提案設定
type DefaultSuggestion struct {
	UrgencyLevel       string `yaml:"urgency_level"`
	RecommendedTiming  string `yaml:"recommended_timing"`
	Reasoning          string `yaml:"reasoning"`
}

// TimeConsideration 時間帯別配慮事項
type TimeConsideration struct {
	Caution       string `yaml:"caution,omitempty"`
	Preference    string `yaml:"preference,omitempty"`
	StrongCaution string `yaml:"strong_caution,omitempty"`
}

// DayConsideration 曜日別配慮事項
type DayConsideration struct {
	Note    string `yaml:"note,omitempty"`
	Caution string `yaml:"caution,omitempty"`
}

// SchedulePromptData スケジュール分析テンプレート用データ
type SchedulePromptData struct {
	MessageText   string
	SelectedTone  string
	CurrentTime   string
	DayOfWeek     string
}

var toneConfig *ToneConfig
var scheduleConfig *ScheduleConfig

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

// LoadScheduleConfig スケジュール設定ファイルを読み込み
func LoadScheduleConfig() (*ScheduleConfig, error) {
	if scheduleConfig != nil {
		return scheduleConfig, nil
	}

	// 設定ファイルのパスを取得
	configPath := getScheduleConfigPath()
	
	// ファイル読み込み
	data, err := os.ReadFile(configPath)
	if err != nil {
		return nil, fmt.Errorf("スケジュール設定ファイルの読み込みに失敗: %w", err)
	}

	// YAML パース
	var config ScheduleConfig
	if err := yaml.Unmarshal(data, &config); err != nil {
		return nil, fmt.Errorf("スケジュール設定の解析に失敗: %w", err)
	}

	scheduleConfig = &config
	return scheduleConfig, nil
}

// GetSchedulePrompt スケジュール分析プロンプトを生成
func (sc *ScheduleConfig) GetSchedulePrompt(messageText, selectedTone string) (string, error) {
	now := time.Now()
	currentTime := now.Format("2006-01-02 15:04:05")
	dayOfWeek := getDayOfWeekInJapanese(now.Weekday())

	// テンプレートを作成
	tmpl, err := template.New("schedule_prompt").Parse(sc.ScheduleAnalysis.InstructionTemplate)
	if err != nil {
		return "", fmt.Errorf("スケジュールプロンプトテンプレートの解析エラー: %w", err)
	}

	// テンプレート実行用データ
	data := SchedulePromptData{
		MessageText:  messageText,
		SelectedTone: selectedTone,
		CurrentTime:  currentTime,
		DayOfWeek:    dayOfWeek,
	}

	// テンプレート実行
	var result strings.Builder
	if err := tmpl.Execute(&result, data); err != nil {
		return "", fmt.Errorf("スケジュールプロンプトテンプレートの実行エラー: %w", err)
	}

	// システムロールを追加して完全なプロンプトを作成
	fullPrompt := sc.SystemRole + "\n\n" + result.String()
	
	return fullPrompt, nil
}

// GetScheduleAIModelConfig スケジュール分析用AIモデル設定を取得
func (sc *ScheduleConfig) GetScheduleAIModelConfig() AIModelConfig {
	return sc.AIModel
}

// getScheduleConfigPath スケジュール設定ファイルのパスを取得
func getScheduleConfigPath() string {
	// 環境変数から設定ファイルパスを取得（カスタマイズ用）
	if customPath := os.Getenv("SCHEDULE_CONFIG_PATH"); customPath != "" {
		return customPath
	}
	
	// デフォルトパス: バイナリと同じディレクトリのconfig/schedule_prompts.yaml
	execPath, err := os.Executable()
	if err != nil {
		// フォールバック: 現在のディレクトリ
		return filepath.Join("config", "schedule_prompts.yaml")
	}
	
	execDir := filepath.Dir(execPath)
	return filepath.Join(execDir, "config", "schedule_prompts.yaml")
}

// getDayOfWeekInJapanese 英語の曜日を日本語に変換
func getDayOfWeekInJapanese(weekday time.Weekday) string {
	days := map[time.Weekday]string{
		time.Sunday:    "日曜日",
		time.Monday:    "月曜日",
		time.Tuesday:   "火曜日",
		time.Wednesday: "水曜日",
		time.Thursday:  "木曜日",
		time.Friday:    "金曜日",
		time.Saturday:  "土曜日",
	}
	return days[weekday]
}

// ReloadConfig 設定ファイルを再読み込み（開発・チューニング用）
func ReloadConfig() error {
	toneConfig = nil
	scheduleConfig = nil
	_, err1 := LoadToneConfig()
	_, err2 := LoadScheduleConfig()
	
	if err1 != nil {
		return err1
	}
	return err2
}