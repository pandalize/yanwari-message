<template>
  <div class="send-friend-request">
    <h2 class="section-title">友達申請を送信</h2>
    
    <form @submit.prevent="sendRequest" class="form">
      <div class="form-group">
        <label for="email" class="label">相手のメールアドレス</label>
        <input
          id="email"
          v-model="form.email"
          type="email"
          required
          class="input"
          placeholder="example@example.com"
          :disabled="loading"
        >
      </div>
      
      <div class="form-group">
        <label for="message" class="label">メッセージ（任意）</label>
        <textarea
          id="message"
          v-model="form.message"
          class="textarea"
          placeholder="よろしくお願いします"
          :disabled="loading"
        ></textarea>
      </div>
      
      <div class="form-actions">
        <button
          type="submit"
          class="btn btn-primary"
          :disabled="loading || !form.email"
        >
          <span v-if="loading" class="loading-spinner">⏳</span>
          <span v-else>申請を送信</span>
        </button>
      </div>
    </form>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref } from 'vue'
import { useFriendsStore } from '@/stores/friends'

const friendsStore = useFriendsStore()
const loading = ref(false)

const form = reactive({
  email: '',
  message: ''
})

const emit = defineEmits<{
  success: []
}>()

async function sendRequest() {
  if (!form.email) return
  
  loading.value = true
  try {
    await friendsStore.sendFriendRequest(form.email.trim(), form.message.trim() || undefined)
    
    // フォームをリセット
    form.email = ''
    form.message = ''
    
    emit('success')
  } catch (error) {
    // エラーはstoreで処理済み
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.send-friend-request {
  /* 親要素のpaddingを活用するため、コンポーネント自体にはpaddingを設定しない */
}

.section-title {
  font-size: var(--font-size-lg);
  font-weight: 600;
  color: var(--text-primary);
  margin: 0 0 24px 0;
}

.form {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.label {
  font-size: 0.9rem;
  font-weight: 500;
  color: #4a5568;
}

.input, .textarea {
  padding: 12px;
  border: 2px solid #e2e8f0;
  border-radius: 8px;
  font-size: 0.9rem;
  transition: border-color 0.2s;
}

.input:focus, .textarea:focus {
  outline: none;
  border-color: #81c784;
  box-shadow: 0 0 0 3px rgba(129, 199, 132, 0.1);
}

.textarea {
  min-height: 80px;
  resize: vertical;
}

.input:disabled, .textarea:disabled {
  background-color: #f7fafc;
  cursor: not-allowed;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  margin-top: 8px;
}

.btn {
  padding: 12px 24px;
  border: none;
  border-radius: 8px;
  font-size: 0.9rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
  display: inline-flex;
  align-items: center;
  gap: 8px;
}

.btn-primary {
  background-color: #81c784;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background-color: #66bb6a;
  transform: translateY(-1px);
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
}

.loading-spinner {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}
</style>