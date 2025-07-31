<template>
  <div class="treemap-view">
    <div class="treemap-controls">
      <div class="controls">
        <div class="group-selector">
          <label>グループ:</label>
          <select v-model="groupBy" @change="updateTreemap">
            <option value="rating">評価別</option>
            <option value="sender">送信者別</option>
            <option value="date">日付別</option>
          </select>
        </div>
        <div class="size-selector">
          <label>サイズ:</label>
          <select v-model="sizeBy" @change="updateTreemap">
            <option value="count">件数</option>
            <option value="rating">評価</option>
            <option value="recent">最新度</option>
          </select>
        </div>
      </div>
    </div>

    <div class="treemap-container" ref="treemapContainer">
      <div v-if="isLoading" class="loading-state">
        <div class="spinner"></div>
        <p>ツリーマップを生成中...</p>
      </div>

      <div v-else-if="treemapData.length === 0" class="empty-state">
        <div class="empty-icon">📈</div>
        <h4>表示できるデータがありません</h4>
        <p>評価付きメッセージがある場合に表示されます</p>
      </div>

      <div v-else class="treemap-svg-container">
        <svg 
          :width="svgWidth" 
          :height="svgHeight" 
          class="treemap-svg"
          @mouseleave="hideTooltip"
        >
          <!-- ツリーマップレクタングル -->
          <g v-for="(item, index) in treemapData" :key="index">
            <rect
              :x="item.x"
              :y="item.y"
              :width="item.width"
              :height="item.height"
              :fill="item.color"
              :stroke="item.selected ? '#2563eb' : '#ffffff'"
              :stroke-width="item.selected ? 3 : 1"
              :opacity="item.opacity || 0.8"
              class="treemap-rect"
              @mouseenter="showTooltip($event, item)"
              @mousemove="moveTooltip($event)"
              @click="selectItem(item)"
            />
            
            <!-- メッセージプレビュー表示 -->
            <g v-if="item.width > 120 && item.height > 80" class="message-preview-group">
              <!-- グループタイトル -->
              <text
                :x="item.x + 8"
                :y="item.y + 16"
                :font-size="Math.min(item.width / 12, 14)"
                :fill="getTextColor(item.color)"
                class="treemap-group-title"
                font-weight="600"
                pointer-events="none"
              >
                {{ item.label }} ({{ item.count }}件)
              </text>
              
              <!-- メッセージプレビュー -->
              <g v-for="(preview, index) in getMessagePreviews(item)" :key="index">
                <!-- 未読メッセージの背景ハイライト -->
                <rect
                  v-if="preview.isUnread"
                  :x="item.x + 4"
                  :y="item.y + 32 + index * 32"
                  :width="item.width - 8"
                  :height="28"
                  :fill="getTextColor(item.color)"
                  opacity="0.1"
                  rx="2"
                  pointer-events="none"
                />
                
                <!-- 送信者名 -->
                <text
                  :x="item.x + 8"
                  :y="item.y + 40 + index * 32"
                  :font-size="Math.min(item.width / 16, 11)"
                  :fill="getTextColor(item.color)"
                  class="treemap-sender-name"
                  :font-weight="preview.isUnread ? '600' : '500'"
                  pointer-events="none"
                >
                  {{ preview.isUnread ? '📬 ' : '' }}{{ preview.senderName }}:
                </text>
                
                <!-- メッセージテキスト -->
                <text
                  :x="item.x + 8"
                  :y="item.y + 52 + index * 32"
                  :font-size="Math.min(item.width / 18, 10)"
                  :fill="getTextColor(item.color)"
                  class="treemap-message-text"
                  :opacity="preview.isUnread ? '0.95' : '0.8'"
                  :font-weight="preview.isUnread ? '500' : '400'"
                  pointer-events="none"
                >
                  {{ preview.messageText }}
                </text>
                
                <!-- 評価表示（評価がある場合） -->
                <text
                  v-if="preview.rating && !preview.isUnread"
                  :x="item.x + item.width - 12"
                  :y="item.y + 40 + index * 32"
                  text-anchor="end"
                  :font-size="Math.min(item.width / 20, 8)"
                  fill="#f59e0b"
                  class="treemap-message-rating"
                  pointer-events="none"
                >
                  {{ '★'.repeat(preview.rating) }}
                </text>
              </g>
              
              <!-- 「他○件」表示 -->
              <text
                v-if="item.messages && item.messages.length > getMessagePreviews(item).length"
                :x="item.x + 8"
                :y="item.y + item.height - 12"
                :font-size="Math.min(item.width / 20, 9)"
                :fill="getTextColor(item.color)"
                class="treemap-more-count"
                opacity="0.7"
                font-style="italic"
                pointer-events="none"
              >
                他{{ item.messages.length - getMessagePreviews(item).length }}件...
              </text>
            </g>

            <!-- 中程度のサイズの場合（簡易表示） -->
            <g v-else-if="item.width > 80 && item.height > 50" class="simple-preview-group">
              <!-- グループタイトル -->
              <text
                :x="item.x + item.width / 2"
                :y="item.y + 20"
                text-anchor="middle"
                :font-size="Math.min(item.width / 10, 12)"
                :fill="getTextColor(item.color)"
                class="treemap-label"
                font-weight="600"
                pointer-events="none"
              >
                {{ item.label }}
              </text>
              
              <!-- 件数表示 -->
              <text
                :x="item.x + item.width / 2"
                :y="item.y + item.height / 2 + 5"
                text-anchor="middle"
                :font-size="Math.min(item.width / 12, 10)"
                :fill="getTextColor(item.color)"
                class="treemap-count"
                pointer-events="none"
              >
                {{ item.count }}件
              </text>
              
              <!-- 代表的な送信者名 -->
              <text
                v-if="getTopSender(item)"
                :x="item.x + item.width / 2"
                :y="item.y + item.height - 15"
                text-anchor="middle"
                :font-size="Math.min(item.width / 14, 9)"
                :fill="getTextColor(item.color)"
                class="treemap-top-sender"
                opacity="0.7"
                pointer-events="none"
              >
                {{ getTopSender(item) }}{{ item.messages && item.messages.length > 1 ? ' 他' : '' }}
              </text>
            </g>

            <!-- 小さいサイズの場合（最小表示） -->
            <g v-else-if="item.width > 40 && item.height > 30" class="minimal-preview-group">
              <text
                :x="item.x + item.width / 2"
                :y="item.y + item.height / 2 - 5"
                text-anchor="middle"
                :font-size="Math.min(item.width / 6, item.height / 4, 10)"
                :fill="getTextColor(item.color)"
                class="treemap-minimal-label"
                font-weight="500"
                pointer-events="none"
              >
                {{ getShortLabel(item.label) }}
              </text>
              
              <text
                :x="item.x + item.width / 2"
                :y="item.y + item.height / 2 + 8"
                text-anchor="middle"
                :font-size="Math.min(item.width / 8, item.height / 6, 8)"
                :fill="getTextColor(item.color)"
                class="treemap-minimal-count"
                pointer-events="none"
              >
                {{ item.count }}
              </text>
            </g>
          </g>
        </svg>

        <!-- ツールチップ -->
        <div
          v-if="tooltip.visible"
          class="treemap-tooltip"
          :style="{
            left: tooltip.x + 'px',
            top: tooltip.y + 'px'
          }"
        >
          <div class="tooltip-header">
            <strong>{{ tooltip.data?.label }}</strong>
          </div>
          <div class="tooltip-content">
            <div v-if="groupBy === 'rating' && tooltip.data?.isUnread" class="tooltip-unread">
              📬 未読メッセージ (要確認)
            </div>
            <div v-else-if="groupBy === 'rating'" class="tooltip-rating">
              評価: {{ '★'.repeat(tooltip.data?.originalValue || 0) }}
            </div>
            <div v-if="groupBy === 'sender'" class="tooltip-sender">
              送信者: {{ tooltip.data?.label }}
            </div>
            <div class="tooltip-stats">
              <div>メッセージ数: {{ tooltip.data?.count }}件</div>
              <div v-if="tooltip.data?.avgRating">
                平均評価: {{ tooltip.data.avgRating.toFixed(1) }}★
              </div>
              <div v-if="tooltip.data?.lastReceived">
                最新: {{ formatDate(tooltip.data.lastReceived) }}
              </div>
              <div v-if="tooltip.data?.isUnread" class="tooltip-priority">
                優先度: 高 (未読のため最大サイズで表示)
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch, nextTick } from 'vue'
import type { InboxMessageWithRating } from '../../services/ratingService'

// Props
interface Props {
  messages: InboxMessageWithRating[]
}

const props = defineProps<Props>()

// Events
const emit = defineEmits<{
  'message-selected': [message: InboxMessageWithRating]
}>()

// State
const groupBy = ref<'rating' | 'sender' | 'date'>('rating')
const sizeBy = ref<'count' | 'rating' | 'recent'>('count')
const isLoading = ref<boolean>(false)
const selectedItem = ref<any>(null)
const treemapContainer = ref<HTMLElement>()

// Tooltip state
const tooltip = ref({
  visible: false,
  x: 0,
  y: 0,
  data: null as any
})

// SVG dimensions
const svgWidth = ref<number>(800)
const svgHeight = ref<number>(600)

// ツリーマップデータの計算
const treemapData = computed(() => {
  if (!props.messages.length) return []
  
  const grouped = groupMessages()
  return calculateTreemap(grouped)
})

// 凡例データ
const legendItems = computed(() => {
  if (groupBy.value === 'rating') {
    return [
      { color: '#2563eb', label: '📬 未読 (最大サイズで表示)' },
      { color: '#22c55e', label: '5★ (最高)' },
      { color: '#eab308', label: '4★ (良い)' },
      { color: '#f97316', label: '3★ (普通)' },
      { color: '#ef4444', label: '1-2★ (低評価)' },
      { color: '#9ca3af', label: '未評価' }
    ]
  } else if (groupBy.value === 'sender') {
    return [
      { color: '#3b82f6', label: '頻繁な送信者' },
      { color: '#8b5cf6', label: '中程度の送信者' },
      { color: '#06b6d4', label: '稀な送信者' }
    ]
  } else {
    return [
      { color: '#22c55e', label: '今週' },
      { color: '#eab308', label: '今月' },
      { color: '#f97316', label: '3ヶ月以内' },
      { color: '#ef4444', label: 'それ以前' }
    ]
  }
})

// Methods
const groupMessages = () => {
  const groups: { [key: string]: any } = {}
  
  props.messages.forEach(message => {
    let key: string
    
    if (groupBy.value === 'rating') {
      // 未読メッセージの特別処理
      if (message.status !== 'read') {
        key = '📬 未読'
      } else {
        key = message.rating ? `${message.rating}★` : '未評価'
      }
    } else if (groupBy.value === 'sender') {
      key = message.senderName || message.senderEmail
    } else { // date
      const date = new Date(message.createdAt)
      const now = new Date()
      const diffDays = (now.getTime() - date.getTime()) / (1000 * 60 * 60 * 24)
      
      if (diffDays <= 7) key = '今週'
      else if (diffDays <= 30) key = '今月'
      else if (diffDays <= 90) key = '3ヶ月以内'
      else key = 'それ以前'
    }
    
    if (!groups[key]) {
      groups[key] = {
        label: key,
        messages: [],
        count: 0,
        totalRating: 0,
        ratedCount: 0,
        lastReceived: null,
        isUnread: key === '📬 未読'
      }
    }
    
    groups[key].messages.push(message)
    groups[key].count++
    
    if (message.rating) {
      groups[key].totalRating += message.rating
      groups[key].ratedCount++
    }
    
    const messageDate = new Date(message.createdAt)
    if (!groups[key].lastReceived || messageDate > new Date(groups[key].lastReceived)) {
      groups[key].lastReceived = message.createdAt
    }
  })
  
  // 平均評価を計算とメッセージソート
  Object.values(groups).forEach((group: any) => {
    if (group.ratedCount > 0) {
      group.avgRating = group.totalRating / group.ratedCount
    }
    
    // メッセージをソート（未読を最初に、その後は新しい順）
    group.messages.sort((a: any, b: any) => {
      // 未読メッセージを最初に
      if (a.status !== 'read' && b.status === 'read') return -1
      if (a.status === 'read' && b.status !== 'read') return 1
      
      // 両方とも未読または既読の場合は新しい順
      return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
    })
  })
  
  return Object.values(groups)
}

const calculateTreemap = (data: any[]) => {
  if (!data.length) return []
  
  // 最高値を事前に計算（未読メッセージのサイズ基準用）
  let maxValue = 0
  
  // 値の計算
  data.forEach((item: any) => {
    if (sizeBy.value === 'count') {
      item.value = item.count
    } else if (sizeBy.value === 'rating') {
      item.value = item.avgRating || 0
    } else { // recent
      const daysSince = item.lastReceived ? 
        (new Date().getTime() - new Date(item.lastReceived).getTime()) / (1000 * 60 * 60 * 24) : 1000
      item.value = Math.max(1, 100 - daysSince) // 最新ほど大きい値
    }
    
    // 未読グループ以外の最高値を記録
    if (!item.isUnread && item.value > maxValue) {
      maxValue = item.value
    }
  })
  
  // 未読メッセージのサイズを最高値と同じに設定
  data.forEach((item: any) => {
    if (item.isUnread && maxValue > 0) {
      item.value = maxValue
      item.originalValue = item.count // 元の値を保持（表示用）
    }
  })
  
  // ソート（未読を最初に表示）
  data.sort((a, b) => {
    if (a.isUnread && !b.isUnread) return -1
    if (!a.isUnread && b.isUnread) return 1
    return b.value - a.value
  })
  
  // ツリーマップ配置計算（簡易版）
  return calculateRectangles(data)
}

const calculateRectangles = (data: any[]) => {
  const totalValue = data.reduce((sum, item) => sum + item.value, 0)
  const containerWidth = svgWidth.value - 20
  const containerHeight = svgHeight.value - 20
  const containerArea = containerWidth * containerHeight
  
  let currentX = 10
  let currentY = 10
  let currentRowHeight = 0
  let remainingWidth = containerWidth
  
  return data.map((item, index) => {
    const area = (item.value / totalValue) * containerArea
    const aspectRatio = 16 / 9 // 理想的なアスペクト比
    
    let width = Math.sqrt(area * aspectRatio)
    let height = area / width
    
    // 現在の行に収まるかチェック
    if (width > remainingWidth && currentX > 10) {
      // 次の行に移動
      currentX = 10
      currentY += currentRowHeight + 5
      currentRowHeight = 0
      remainingWidth = containerWidth
    }
    
    // 幅を調整
    width = Math.min(width, remainingWidth)
    height = area / width
    
    const rect = {
      x: currentX,
      y: currentY,
      width: Math.max(30, width), // 最小幅
      height: Math.max(20, height), // 最小高さ
      color: getColor(item),
      label: item.label,
      value: item.isUnread ? 
        `${item.originalValue || item.count}` : // 未読は実際の件数を表示
        (sizeBy.value === 'rating' ? item.value.toFixed(1) : Math.round(item.value)),
      originalValue: groupBy.value === 'rating' && item.label !== '未評価' && !item.isUnread ? 
        parseInt(item.label.replace('★', '')) : null,
      count: item.count,
      avgRating: item.avgRating,
      lastReceived: item.lastReceived,
      messages: item.messages,
      selected: selectedItem.value?.label === item.label,
      opacity: item.isUnread ? 0.95 : 0.8, // 未読は少し濃く表示
      isUnread: item.isUnread
    }
    
    currentX += rect.width + 5
    currentRowHeight = Math.max(currentRowHeight, rect.height)
    remainingWidth -= rect.width + 5
    
    return rect
  })
}

const getColor = (item: any) => {
  if (groupBy.value === 'rating') {
    // 未読メッセージは特別な色（目立つ青色）
    if (item.label === '📬 未読') return '#2563eb'
    if (item.label === '未評価') return '#9ca3af'
    const rating = parseInt(item.label.replace('★', ''))
    if (rating <= 2) return '#ef4444'
    if (rating === 3) return '#f97316'
    if (rating === 4) return '#eab308'
    return '#22c55e'
  } else if (groupBy.value === 'sender') {
    const colors = ['#3b82f6', '#8b5cf6', '#06b6d4', '#ec4899', '#10b981']
    return colors[Math.abs(item.label.charCodeAt(0)) % colors.length]
  } else { // date
    const colorMap: { [key: string]: string } = {
      '今週': '#22c55e',
      '今月': '#eab308',
      '3ヶ月以内': '#f97316',
      'それ以前': '#ef4444'
    }
    return colorMap[item.label] || '#9ca3af'
  }
}

const getTextColor = (bgColor: string) => {
  // 背景色に応じてテキスト色を決定
  const color = bgColor.replace('#', '')
  const r = parseInt(color.substr(0, 2), 16)
  const g = parseInt(color.substr(2, 2), 16)
  const b = parseInt(color.substr(4, 2), 16)
  const brightness = (r * 299 + g * 587 + b * 114) / 1000
  return brightness > 128 ? '#000000' : '#ffffff'
}

const showTooltip = (event: MouseEvent, item: any) => {
  tooltip.value = {
    visible: true,
    x: event.clientX + 10,
    y: event.clientY - 10,
    data: item
  }
}

const moveTooltip = (event: MouseEvent) => {
  tooltip.value.x = event.clientX + 10
  tooltip.value.y = event.clientY - 10
}

const hideTooltip = () => {
  tooltip.value.visible = false
}

const selectItem = (item: any) => {
  selectedItem.value = selectedItem.value?.label === item.label ? null : item
}

const openMessage = (message: InboxMessageWithRating) => {
  emit('message-selected', message)
}

const updateTreemap = async () => {
  isLoading.value = true
  await nextTick()
  setTimeout(() => {
    isLoading.value = false
  }, 300)
}

const formatDate = (dateString: string) => {
  const date = new Date(dateString)
  return date.toLocaleDateString('ja-JP', { 
    year: 'numeric', 
    month: 'short', 
    day: 'numeric' 
  })
}

// メッセージプレビュー用のヘルパー関数
const getMessagePreviews = (item: any) => {
  if (!item.messages || item.messages.length === 0) return []
  
  // 利用可能な高さに基づいて表示件数を計算
  const maxPreviews = Math.floor((item.height - 60) / 32)
  const limitedPreviews = Math.min(maxPreviews, 4) // 最大4件まで
  
  // メッセージは既にソート済み（未読優先、その後新しい順）
  return item.messages
    .slice(0, limitedPreviews)
    .map((message: any) => {
      // 文字数制限を動的に調整
      const senderMaxLength = Math.max(8, Math.floor(item.width / 12))
      const messageMaxLength = Math.max(15, Math.floor(item.width / 8))
      
      return {
        senderName: truncateText(message.senderName || message.senderEmail, senderMaxLength),
        messageText: truncateText(message.finalText || message.originalText, messageMaxLength),
        isUnread: message.status !== 'read',
        rating: message.rating
      }
    })
}

const getTopSender = (item: any) => {
  if (!item.messages || item.messages.length === 0) return null
  
  // 最も多くメッセージを送っている送信者を取得
  const senderCounts: { [key: string]: number } = {}
  item.messages.forEach((message: any) => {
    const sender = message.senderName || message.senderEmail
    senderCounts[sender] = (senderCounts[sender] || 0) + 1
  })
  
  const topSender = Object.entries(senderCounts)
    .sort(([,a], [,b]) => b - a)[0]
  
  return topSender ? truncateText(topSender[0], Math.floor(item.width / 10)) : null
}

const getShortLabel = (label: string) => {
  if (label === '📬 未読') return '📬'
  if (label.includes('★')) return label.replace('★', '⭐')
  if (label === '未評価') return '未評価'
  
  // 長いラベルを短縮
  return truncateText(label, 8)
}

const truncateText = (text: string, maxLength: number) => {
  if (!text) return ''
  if (text.length <= maxLength) return text
  return text.substring(0, maxLength - 1) + '…'
}

// Resize observer
const updateDimensions = () => {
  if (treemapContainer.value) {
    const rect = treemapContainer.value.getBoundingClientRect()
    svgWidth.value = Math.max(300, rect.width - 20)
    svgHeight.value = Math.max(200, rect.height - 20)
  }
}

onMounted(() => {
  updateDimensions()
  window.addEventListener('resize', updateDimensions)
})

watch(() => props.messages, () => {
  updateTreemap()
}, { deep: true })
</script>

<style scoped>
.treemap-view {
  background: transparent;
  border-radius: 0;
  padding: 0;
  box-shadow: none;
  height: 100%;
  display: flex;
  flex-direction: column;
}

.treemap-controls {
  position: absolute;
  top: 10px;
  right: 10px;
  z-index: 10;
  flex-shrink: 0;
}

.controls {
  display: flex;
  gap: 10px;
  align-items: center;
  background: rgba(255, 255, 255, 0.9);
  padding: 8px;
  border-radius: 6px;
  border: 1px solid #e5e7eb;
}

.group-selector,
.size-selector {
  display: flex;
  align-items: center;
  gap: 4px;
}

.group-selector label,
.size-selector label {
  font-size: 0.75rem;
  color: #6b7280;
  font-weight: 500;
  white-space: nowrap;
}

.group-selector select,
.size-selector select {
  padding: 4px 8px;
  border: 1px solid #d1d5db;
  border-radius: 4px;
  font-size: 0.75rem;
  background: white;
  cursor: pointer;
}

.treemap-container {
  position: relative;
  flex: 1;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  background: #f9fafb;
  overflow: hidden;
}

.loading-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #f3f3f3;
  border-top: 4px solid #3b82f6;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-bottom: 16px;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  color: #6b7280;
}

.empty-icon {
  font-size: 4rem;
  margin-bottom: 16px;
  opacity: 0.5;
}

.treemap-svg-container {
  position: relative;
  overflow: hidden;
}

.treemap-svg {
  display: block;
}

.treemap-rect {
  cursor: pointer;
  transition: all 0.2s ease;
}

.treemap-rect:hover {
  stroke-width: 2 !important;
  opacity: 1 !important;
}

.treemap-label {
  font-weight: 600;
  font-family: system-ui, -apple-system, sans-serif;
}

.treemap-value {
  font-weight: 500;
  font-family: system-ui, -apple-system, sans-serif;
}

/* メッセージプレビュー用スタイル */
.treemap-group-title {
  font-family: system-ui, -apple-system, sans-serif;
  font-weight: 600;
}

.treemap-sender-name {
  font-family: system-ui, -apple-system, sans-serif;
  font-weight: 500;
}

.treemap-message-text {
  font-family: system-ui, -apple-system, sans-serif;
  font-weight: 400;
}

.treemap-more-count {
  font-family: system-ui, -apple-system, sans-serif;
  font-style: italic;
}

.treemap-count {
  font-family: system-ui, -apple-system, sans-serif;
  font-weight: 600;
}

.treemap-top-sender {
  font-family: system-ui, -apple-system, sans-serif;
  font-weight: 400;
}

.treemap-minimal-label {
  font-family: system-ui, -apple-system, sans-serif;
  font-weight: 500;
}

.treemap-minimal-count {
  font-family: system-ui, -apple-system, sans-serif;
  font-weight: 600;
}

.treemap-message-rating {
  font-family: system-ui, -apple-system, sans-serif;
  font-weight: 400;
}

/* 矩形内テキストの可読性向上 */
.message-preview-group text {
  text-shadow: 0 0 2px rgba(255, 255, 255, 0.8);
}

.simple-preview-group text {
  text-shadow: 0 0 2px rgba(255, 255, 255, 0.8);
}

.minimal-preview-group text {
  text-shadow: 0 0 2px rgba(255, 255, 255, 0.8);
}

.treemap-tooltip {
  position: fixed;
  background: rgba(0, 0, 0, 0.9);
  color: white;
  padding: 12px;
  border-radius: 8px;
  font-size: 0.875rem;
  max-width: 250px;
  z-index: 1000;
  pointer-events: none;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
}

.tooltip-header {
  margin-bottom: 8px;
  font-size: 1rem;
  border-bottom: 1px solid rgba(255, 255, 255, 0.2);
  padding-bottom: 4px;
}

.tooltip-content {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.tooltip-rating {
  color: #fbbf24;
  font-weight: 500;
}

.tooltip-unread {
  color: #2563eb;
  font-weight: 600;
  background: rgba(37, 99, 235, 0.1);
  padding: 4px 8px;
  border-radius: 4px;
  border: 1px solid rgba(37, 99, 235, 0.3);
}

.tooltip-priority {
  color: #dc2626;
  font-weight: 500;
  font-size: 0.75rem;
  background: rgba(220, 38, 38, 0.1);
  padding: 2px 6px;
  border-radius: 3px;
  border: 1px solid rgba(220, 38, 38, 0.2);
}


/* レスポンシブ対応 */
@media (max-width: 768px) {
  .treemap-controls {
    top: 5px;
    right: 5px;
  }
  
  .controls {
    gap: 5px;
    padding: 6px;
  }
  
  .group-selector label,
  .size-selector label {
    font-size: 0.7rem;
  }
  
  .group-selector select,
  .size-selector select {
    padding: 3px 6px;
    font-size: 0.7rem;
  }
}
</style>