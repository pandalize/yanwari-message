<template>
  <div class="recipient-selector">
    <label class="selector-label">📧 送信先</label>
    
    <!-- 選択済み受信者 -->
    <div v-if="selectedRecipient" class="selected-recipient">
      <div class="recipient-info">
        <span class="recipient-name">{{ selectedRecipient.name }}</span>
        <span class="recipient-email">{{ selectedRecipient.email }}</span>
      </div>
      <button
        @click="clearSelection"
        class="clear-button"
        title="選択を解除"
      >
        ✕
      </button>
    </div>

    <!-- 検索入力 -->
    <div v-else class="search-container">
      <input
        v-model="searchQuery"
        @input="handleSearch"
        @focus="showSuggestions = true"
        type="text"
        placeholder="名前またはメールアドレスで検索..."
        class="search-input"
        :class="{ 'has-suggestions': showSuggestions && suggestions.length > 0 }"
      />
      
      <!-- 検索候補 -->
      <div
        v-if="showSuggestions && suggestions.length > 0"
        class="suggestions-dropdown"
      >
        <div
          v-for="user in suggestions"
          :key="user.id"
          @click="selectRecipient(user)"
          class="suggestion-item"
        >
          <div class="suggestion-info">
            <span class="suggestion-name">{{ user.name }}</span>
            <span class="suggestion-email">{{ user.email }}</span>
          </div>
        </div>
      </div>

      <!-- 検索状態表示 -->
      <div v-if="isSearching" class="search-status">
        🔍 検索中...
      </div>
      
      <div v-else-if="searchQuery && suggestions.length === 0 && !isSearching" class="search-status">
        該当するユーザーが見つかりません
      </div>
    </div>

    <!-- ヒント -->
    <small class="selector-hint">
      {{ selectedRecipient ? 'クリックして選択を変更できます' : 'ユーザーを検索して選択してください' }}
    </small>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, nextTick } from 'vue'
import { userService, type User } from '@/services/userService'

interface Props {
  modelValue?: User | null
  disabled?: boolean
}

interface Emits {
  (e: 'update:modelValue', value: User | null): void
}

const props = withDefaults(defineProps<Props>(), {
  modelValue: null,
  disabled: false
})

const emit = defineEmits<Emits>()

const searchQuery = ref('')
const suggestions = ref<User[]>([])
const selectedRecipient = ref<User | null>(props.modelValue)
const showSuggestions = ref(false)
const isSearching = ref(false)
const searchTimeout = ref<NodeJS.Timeout | null>(null)

// プロップスの変更を監視
watch(() => props.modelValue, (newValue) => {
  selectedRecipient.value = newValue
})

// 検索処理
const handleSearch = async () => {
  const query = searchQuery.value.trim()
  
  if (searchTimeout.value) {
    clearTimeout(searchTimeout.value)
  }

  if (!query) {
    suggestions.value = []
    showSuggestions.value = false
    return
  }

  searchTimeout.value = setTimeout(async () => {
    isSearching.value = true
    
    try {
      const response = await userService.searchUsers(query, 5)
      suggestions.value = response.data.users
      showSuggestions.value = true
    } catch (error) {
      console.error('ユーザー検索エラー:', error)
      suggestions.value = []
    } finally {
      isSearching.value = false
    }
  }, 300) // 300ms のデバウンス
}

// 受信者を選択
const selectRecipient = (user: User) => {
  selectedRecipient.value = user
  searchQuery.value = ''
  suggestions.value = []
  showSuggestions.value = false
  emit('update:modelValue', user)
}

// 選択をクリア
const clearSelection = () => {
  selectedRecipient.value = null
  searchQuery.value = ''
  suggestions.value = []
  showSuggestions.value = false
  emit('update:modelValue', null)
}

// 外部クリックで候補を非表示
const handleClickOutside = (event: MouseEvent) => {
  const target = event.target as HTMLElement
  if (!target.closest('.recipient-selector')) {
    showSuggestions.value = false
  }
}

// マウント時とアンマウント時の処理
import { onMounted, onUnmounted } from 'vue'

onMounted(() => {
  document.addEventListener('click', handleClickOutside)
})

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside)
  if (searchTimeout.value) {
    clearTimeout(searchTimeout.value)
  }
})
</script>

<style scoped>
.recipient-selector {
  position: relative;
  margin-bottom: 1rem;
}

.selector-label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 600;
  color: #333;
}

.selected-recipient {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: #e3f2fd;
  border: 1px solid #2196f3;
  border-radius: 4px;
  padding: 0.75rem;
  cursor: pointer;
  transition: all 0.2s;
}

.selected-recipient:hover {
  background: #bbdefb;
}

.recipient-info {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.recipient-name {
  font-weight: 600;
  color: #1976d2;
}

.recipient-email {
  font-size: 0.875rem;
  color: #1565c0;
}

.clear-button {
  background: none;
  border: none;
  color: #1976d2;
  cursor: pointer;
  padding: 0.25rem;
  border-radius: 50%;
  transition: background-color 0.2s;
  font-size: 1rem;
}

.clear-button:hover {
  background-color: rgba(25, 118, 210, 0.1);
}

.search-container {
  position: relative;
}

.search-input {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 1rem;
  transition: border-color 0.2s;
}

.search-input:focus {
  outline: none;
  border-color: #007bff;
  box-shadow: 0 0 0 2px rgba(0, 123, 255, 0.25);
}

.search-input.has-suggestions {
  border-bottom-left-radius: 0;
  border-bottom-right-radius: 0;
}

.suggestions-dropdown {
  position: absolute;
  top: 100%;
  left: 0;
  right: 0;
  background: white;
  border: 1px solid #ddd;
  border-top: none;
  border-radius: 0 0 4px 4px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  z-index: 1000;
  max-height: 200px;
  overflow-y: auto;
}

.suggestion-item {
  padding: 0.75rem;
  cursor: pointer;
  border-bottom: 1px solid #f0f0f0;
  transition: background-color 0.2s;
}

.suggestion-item:hover {
  background-color: #f8f9fa;
}

.suggestion-item:last-child {
  border-bottom: none;
}

.suggestion-info {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.suggestion-name {
  font-weight: 600;
  color: #333;
}

.suggestion-email {
  font-size: 0.875rem;
  color: #666;
}

.search-status {
  padding: 0.75rem;
  text-align: center;
  color: #666;
  font-size: 0.875rem;
  background: #f8f9fa;
  border: 1px solid #ddd;
  border-top: none;
  border-radius: 0 0 4px 4px;
}

.selector-hint {
  display: block;
  margin-top: 0.25rem;
  color: #666;
  font-size: 0.875rem;
}

/* 無効状態 */
.recipient-selector[disabled] .search-input,
.recipient-selector[disabled] .selected-recipient {
  opacity: 0.6;
  cursor: not-allowed;
  pointer-events: none;
}
</style>