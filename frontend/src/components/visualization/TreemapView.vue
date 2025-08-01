<template>
  <div class="treemap-view">

    <div class="treemap-container" ref="treemapContainer">
      <div v-if="isLoading" class="loading-state">
        <div class="spinner"></div>
        <p>ツリーマップを生成中...</p>
      </div>

      <div v-else-if="treemapData.length === 0" class="empty-state">
        <div class="empty-icon">📈</div>
        <h4>表示できるデータがありません</h4>
        <p>メッセージがある場合にツリーマップが表示されます</p>
      </div>

      <div v-else class="treemap-svg-container">
        <svg
          :width="svgWidth"
          :height="svgHeight"
          class="treemap-svg"
        >
          <g v-for="(item, index) in treemapData" :key="item.id || index">
            <rect
              :x="item.x"
              :y="item.y"
              :width="item.width"
              :height="item.height"
              :fill="item.color"
              :stroke="item.isBorder ? (item.stroke || '#1f2937') : (item.selected ? '#2563eb' : '#ffffff')"
              :stroke-width="item.isBorder ? (item.strokeWidth || 2) : (item.selected ? 3 : 1)"
              :opacity="item.isBorder ? 0.1 : (item.opacity || 0.8)"
              :class="item.isBorder ? 'treemap-border' : 'treemap-rect'"
              @click="!item.isBorder && selectItem(item)"
            />

            <text
              v-if="item.level === 1 && item.width > 80 && item.height > 30"
              :x="item.x + 8"
              :y="item.y + 20"
              text-anchor="start"
              :font-size="Math.min(item.width / 6, 20)"
              :fill="getTextColor(item.color)"
              class="treemap-sender-label"
              font-weight="700"
              pointer-events="none"
            >
              👤 {{ item.label }}
            </text>

            <text
              v-if="item.level === 2 && item.width > 60 && item.height > 25"
              :x="item.x + 6"
              :y="item.y + 16"
              text-anchor="start"
              :font-size="Math.min(item.width / 8, 18)"
              :fill="getTextColor(item.color)"
              class="treemap-rating-label"
              font-weight="600"
              pointer-events="none"
            >
              {{ item.label }}
            </text>

            <g v-if="item.level >= 3">
              <text
                v-if="item.width > 25 && item.height > 20"
                :x="item.x + item.width / 2"
                :y="item.y + Math.min(12, item.height * 0.4)"
                text-anchor="middle"
                :font-size="Math.max(Math.min(item.width / 5, item.height / 3, 12), 8)"
                :fill="getTextColor(item.color)"
                class="treemap-message-sender"
                font-weight="600"
                pointer-events="none"
              >
                {{ (item.senderName || '不明').substring(0, Math.max(Math.floor(item.width / 8), 3)) }}
              </text>

              <!-- 改行対応のメッセージテキスト -->
              <g v-if="item.width > 35 && item.height > 30">
                <text
                  v-for="(line, lineIndex) in getMessageLines(item.message, item.width, item.height)"
                  :key="lineIndex"
                  :x="item.x + item.width / 2"
                  :y="getLineY(item, lineIndex, getMessageLines(item.message, item.width, item.height).length)"
                  text-anchor="middle"
                  :font-size="getMessageFontSize(item)"
                  :fill="getTextColor(item.color)"
                  class="treemap-message-preview"
                  pointer-events="none"
                >
                  {{ line }}
                </text>
              </g>

              <text
                v-if="item.width > 20 && item.height > 25"
                :x="item.x + item.width / 2"
                :y="item.y + item.height - Math.min(4, item.height * 0.1)"
                text-anchor="middle"
                :font-size="Math.max(Math.min(item.width / 6, item.height / 3, 12), 8)"
                :fill="item.rating ? '#000000' : getTextColor(item.color)"
                class="treemap-message-rating"
                font-weight="500"
                pointer-events="none"
              >
                {{ item.rating ? '★'.repeat(Math.min(item.rating, Math.floor(item.width / 8))) : (item.isUnread ? '未読' : '未評価') }}
              </text>
            </g>
          </g>
        </svg>

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
const isLoading = ref<boolean>(false)
const selectedItem = ref<any>(null)
const treemapContainer = ref<HTMLElement>()


// SVG dimensions
const svgWidth = ref<number>(800)
const svgHeight = ref<number>(600)

// ツリーマップデータの計算
const treemapData = computed(() => {
  if (!props.messages.length) return []

  const hierarchyData = groupMessages()
  return calculateTreemap(hierarchyData)
})

// 階層構造を持つツリーマップデータ構造
interface TreemapNode {
  id: string
  name: string
  value?: number
  children?: TreemapNode[]
  message?: any
  color?: string
  level: number
  parent?: TreemapNode
}

// Methods
const groupMessages = () => {

  // 送信者別にグループ化
  const senderGroups = new Map<string, any[]>()

  props.messages.forEach(message => {
    const senderKey = message.senderName || message.senderEmail || '不明'
    if (!senderGroups.has(senderKey)) {
      senderGroups.set(senderKey, [])
    }
    senderGroups.get(senderKey)!.push(message)
  })

  // 階層構造を構築: 送信者 → 評価 → メッセージ
  const rootChildren: TreemapNode[] = []

  senderGroups.forEach((messages, senderName) => {
    // 評価別にさらにグループ化
    const ratingGroups = new Map<string, any[]>()

    messages.forEach(message => {
      const ratingKey = message.rating ? `★${message.rating}` : (message.status !== 'read' ? '未読' : '未評価')
      if (!ratingGroups.has(ratingKey)) {
        ratingGroups.set(ratingKey, [])
      }
      ratingGroups.get(ratingKey)!.push(message)
    })

    // 評価レベルのノードを作成（ソート順を定義）
    const ratingOrder = ['未読', '未評価', '★5', '★4', '★3', '★2', '★1']
    const ratingChildren: TreemapNode[] = []
    
    // 定義された順序で処理
    ratingOrder.forEach(ratingName => {
      if (!ratingGroups.has(ratingName)) return
      
      const ratingMessages = ratingGroups.get(ratingName)!
      // 評価に基づく重み付けを計算
      const ratingWeight = getRatingWeight(ratingName)

      // 個別メッセージのノードを作成（評価に基づく重み付け）
      const messageChildren: TreemapNode[] = ratingMessages.map(message => ({
        id: message.id,
        name: getMessagePreview(message, 15),
        value: ratingWeight, // 評価に基づく重み
        message: message,
        level: 3,
        color: getMessageColor(message)
      }))

      // 評価グループの総値を計算
      const totalValue = ratingMessages.length * ratingWeight

      ratingChildren.push({
        id: `${senderName}-${ratingName}`,
        name: ratingName,
        value: totalValue,
        children: messageChildren,
        level: 2,
        color: getRatingColor(ratingName)
      })
    })

    // 送信者レベルのノードを作成（子ノードの重み付き合計）
    const senderTotalValue = ratingChildren.reduce((sum, child) => sum + (child.value || 0), 0)

    rootChildren.push({
      id: senderName,
      name: senderName,
      value: senderTotalValue,
      children: ratingChildren,
      level: 1,
      color: getSenderColor(senderName)
    })
  })

  // 送信者を優先順位に基づいてソート（最高優先度の評価を持つ送信者を先に）
  const getSenderPriority = (sender: TreemapNode): number => {
    const children = sender.children || []
    if (children.some(c => c.name === '未読')) return 10
    if (children.some(c => c.name === '未評価')) return 8
    if (children.some(c => c.name === '★5')) return 6
    if (children.some(c => c.name === '★4')) return 5
    if (children.some(c => c.name === '★3')) return 4
    if (children.some(c => c.name === '★2')) return 3
    if (children.some(c => c.name === '★1')) return 2
    return 1
  }
  
  // 送信者を優先順位でソート
  rootChildren.sort((a, b) => getSenderPriority(b) - getSenderPriority(a))

  return {
    id: 'root',
    name: 'メッセージ',
    children: rootChildren,
    level: 0
  }
}

const calculateTreemap = (hierarchyData: TreemapNode) => {
  const containerWidth = svgWidth.value - 20
  const containerHeight = svgHeight.value - 20

  // 階層構造を再帰的にレイアウト
  const layoutHierarchy = (node: TreemapNode, x: number, y: number, width: number, height: number): any[] => {
    const result: any[] = []

    if (!node.children || node.children.length === 0) {
      // 葉ノード（個別メッセージ）
      return [{
        id: node.id,
        x: x,
        y: y,
        width: width,
        height: height,
        color: node.color || getMessageColor(node.message),
        label: node.name,
        message: node.message,
        level: node.level,
        opacity: node.message?.status !== 'read' ? 0.95 : 0.8,
        isUnread: node.message?.status !== 'read',
        rating: node.message?.rating,
        senderName: node.message?.senderName || node.message?.senderEmail,
        value: node.value
      }]
    }

    // 子ノードの総値を計算
    const totalValue = node.children.reduce((sum, child) => sum + (child.value || 1), 0)

    // TreeMapアルゴリズム
    const rectangles = squarify(node.children, x, y, width, height, totalValue)

    rectangles.forEach((rect, index) => {
      const child = node.children![index]

      if (child.children && child.children.length > 0) {
        // 親ノードの境界線を描画
        if (child.level <= 2) {
          result.push({
            id: `${child.id}-border`,
            x: rect.x,
            y: rect.y,
            width: rect.width,
            height: rect.height,
            color: 'transparent',
            stroke: child.level === 1 ? '#1f2937' : '#6b7280',
            strokeWidth: child.level === 1 ? 3 : 2,
            label: child.name,
            level: child.level,
            isBorder: true
          })
        }

        // 子ノードを再帰的にレイアウト
        const childRects = layoutHierarchy(child, rect.x + 2, rect.y + 2, rect.width - 4, rect.height - 4)
        result.push(...childRects)
      } else {
        // 葉ノード
        result.push({
          id: child.id,
          x: rect.x,
          y: rect.y,
          width: rect.width,
          height: rect.height,
          color: child.color || getMessageColor(child.message),
          label: child.name,
          message: child.message,
          level: child.level,
          opacity: child.message?.status !== 'read' ? 0.95 : 0.8,
          isUnread: child.message?.status !== 'read',
          rating: child.message?.rating,
          senderName: child.message?.senderName || child.message?.senderEmail,
          value: child.value
        })
      }
    })

    return result
  }

  return layoutHierarchy(hierarchyData, 10, 10, containerWidth, containerHeight)
}

// 最もシンプルな面積比例分割アルゴリズム
const squarify = (children: TreemapNode[], x: number, y: number, width: number, height: number, totalValue: number) => {
  if (children.length === 0) return []

  const rectangles: { x: number, y: number, width: number, height: number }[] = []
  const totalArea = width * height

  let currentX = x
  let currentY = y
  let remainingWidth = width
  let remainingHeight = height

  for (let i = 0; i < children.length; i++) {
    const child = children[i]
    const childValue = child.value || 1
    const areaRatio = childValue / totalValue
    const targetArea = areaRatio * totalArea

    let rectWidth, rectHeight

    if (i === children.length - 1) {
      // 最後の要素は残り全部
      rectWidth = remainingWidth
      rectHeight = remainingHeight
    } else {
      // 長い辺に沿って分割
      if (remainingWidth >= remainingHeight) {
        // 横に分割
        rectWidth = targetArea / remainingHeight
        rectHeight = remainingHeight
        rectWidth = Math.min(rectWidth, remainingWidth)
      } else {
        // 縦に分割
        rectHeight = targetArea / remainingWidth
        rectWidth = remainingWidth
        rectHeight = Math.min(rectHeight, remainingHeight)
      }

      // 最小サイズ保証
      rectWidth = Math.max(rectWidth, 30)
      rectHeight = Math.max(rectHeight, 25)
    }

    rectangles.push({
      x: currentX,
      y: currentY,
      width: rectWidth,
      height: rectHeight
    })

    // 次の位置を計算
    if (remainingWidth >= remainingHeight) {
      currentX += rectWidth
      remainingWidth -= rectWidth
    } else {
      currentY += rectHeight
      remainingHeight -= rectHeight
    }
  }

  return rectangles
}

// 評価に基づく重み付け関数
const getRatingWeight = (ratingName: string): number => {
  if (ratingName === '未読') return 4      // 未読は★5と同じサイズ
  if (ratingName === '未評価') return 4   // 未評価も★5と同じサイズ
  if (ratingName === '★5') return 5        // 星5
  if (ratingName === '★4') return 4        // 星4
  if (ratingName === '★3') return 3        // 星3
  if (ratingName === '★2') return 2        // 星2
  if (ratingName === '★1') return 1        // 星1は最小
  return 1                                  // デフォルト
}

// 階層構造用の色分け関数群
const getSenderColor = (senderName: string) => {
  // 送信者名のハッシュ値を基にした色生成
  const hash = senderName.split('').reduce((a, b) => {
    a = ((a << 5) - a) + b.charCodeAt(0)
    return a & a
  }, 0)

  const hue = Math.abs(hash) % 360
  return `hsl(${hue}, 65%, 75%)`
}

const getRatingColor = (ratingName: string) => {
  // 評価に基づく色分け
  if (ratingName === '未読') return '#3b82f6'
  if (ratingName === '未評価') return '#9ca3af'
  if (ratingName === '★1') return '#ef4444'
  if (ratingName === '★2') return '#f97316'
  if (ratingName === '★3') return '#eab308'
  if (ratingName === '★4') return '#84cc16'
  if (ratingName === '★5') return '#22c55e'
  return '#6b7280'
}

const getMessageColor = (message: any) => {
  if (!message) return '#f3f4f6'

  // 未読メッセージは特別な色（目立つ青色）
  if (message.status !== 'read') return '#dbeafe'

  // 評価に基づく色分け（薄い色合い）
  if (!message.rating) return '#f3f4f6' // 未評価は薄い灰色

  const rating = message.rating
  if (rating <= 1) return '#87cefa'
  if (rating <= 2) return '#b0e0e6'
  if (rating === 3) return '#fef3c7'
  if (rating === 4) return '#ffb6c1'
  return '#ff7f50'
}

const getTextColor = (bgColor: string) => {
  // 背景色に応じてテキスト色を決定
  const color = bgColor.replace('#', '')
  const r = parseInt(color.substring(0, 2), 16)
  const g = parseInt(color.substring(2, 4), 16)
  const b = parseInt(color.substring(4, 6), 16)
  const brightness = (r * 299 + g * 587 + b * 114) / 1000
  return brightness > 128 ? '#000000' : '#ffffff'
}


const selectItem = (item: any) => {
  // 個別メッセージを直接選択
  if (item.message) {
    emit('message-selected', item.message)
  }

  // 選択状態を切り替え
  selectedItem.value = selectedItem.value?.id === item.id ? null : item
}

// 枠のサイズによって1行あたりの最大文字数を決定
const getCharsPerLine = (width: number): number => {
  if (width >= 120) {
    return 12 // 大きい枠: 12文字/行
  } else if (width >= 80) {
    return 8  // 中くらいの枠: 8文字/行
  } else if (width >= 60) {
    return 6  // 小さい枠: 6文字/行
  } else if (width >= 40) {
    return 4  // とても小さい枠: 4文字/行
  } else {
    return 3  // 最小枠: 3文字/行
  }
}

// 枠の高さによって最大行数を決定
const getMaxLines = (height: number): number => {
  if (height >= 80) {
    return 3 // 高い枠: 3行
  } else if (height >= 60) {
    return 2 // 中くらいの枠: 2行
  } else {
    return 1 // 小さい枠: 1行
  }
}

// メッセージを複数行に分割
const getMessageLines = (message: any, width: number, height: number): string[] => {
  if (!message) return ['']
  
  const text = message.finalText || message.originalText || ''
  if (!text) return ['']
  
  const charsPerLine = getCharsPerLine(width)
  const maxLines = getMaxLines(height)
  const totalMaxChars = charsPerLine * maxLines
  
  // 全体の文字数が制限を超える場合は省略
  const displayText = text.length > totalMaxChars 
    ? text.substring(0, totalMaxChars - 1) + '…'
    : text
  
  // 行に分割
  const lines: string[] = []
  let remainingText = displayText
  
  for (let i = 0; i < maxLines && remainingText.length > 0; i++) {
    const lineText = remainingText.substring(0, charsPerLine)
    lines.push(lineText)
    remainingText = remainingText.substring(charsPerLine)
  }
  
  return lines.length > 0 ? lines : ['']
}

// 行のY座標を計算（中央揃え）
const getLineY = (item: any, lineIndex: number, totalLines: number): number => {
  const fontSize = getMessageFontSize(item)
  const lineHeight = fontSize * 1.2 // 行間を少し広げる
  const totalTextHeight = totalLines * lineHeight
  const startY = item.y + item.height / 2 - totalTextHeight / 2 + fontSize * 0.8
  return startY + (lineIndex * lineHeight)
}

// メッセージフォントサイズを取得
const getMessageFontSize = (item: any): number => {
  return Math.max(Math.min(item.width / 8, item.height / 5, 10), 7)
}

const getMessagePreview = (message: any, maxLength: number = 12) => {
  if (!message) return ''
  const text = message.finalText || message.originalText || ''
  if (!text) return ''
  
  const length = Math.max(maxLength, 3) // 最小3文字
  
  // 文字数が制限を超える場合は省略記号を付ける
  if (text.length > length) {
    return text.substring(0, length - 1) + '…' // 日本語の省略記号を使用
  }
  
  return text
}

const formatDate = (dateString: string) => {
  const date = new Date(dateString)
  return date.toLocaleDateString('ja-JP', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  })
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

// メッセージデータの変更を監視してツリーマップを更新
watch(() => props.messages, () => {
  // 強制的に再レンダリングをトリガー
  if (treemapContainer.value) {
    nextTick(() => {
      updateDimensions()
    })
  }
}, { deep: true, immediate: true })
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

.treemap-svg text {
  font-family: system-ui, -apple-system, sans-serif;
}

.treemap-rect {
  cursor: pointer;
  transition: all 0.2s ease;
}

.treemap-rect:hover {
  stroke-width: 2 !important;
  opacity: 1 !important;
}

/* 階層構造用のスタイル */
.treemap-border {
  pointer-events: none;
  transition: all 0.2s ease;
}

.treemap-sender-label {
  text-shadow: 0 0 3px rgba(255, 255, 255, 0.8);
}

.treemap-rating-label {
  text-shadow: 0 0 2px rgba(255, 255, 255, 0.6);
}

.treemap-message-sender {
  text-shadow: 0 0 2px rgba(255, 255, 255, 0.5);
}

.treemap-message-rating {
  text-shadow: 0 0 2px rgba(255, 255, 255, 0.5);
}


</style>