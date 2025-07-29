<template>
  <div style="padding: 20px; background: white; min-height: 100vh;">
    <h1>✅ SimpleHistoryView が正常に表示されています！</h1>
    <p>現在時刻: {{ currentTime }}</p>
    
    <div style="margin-top: 20px; padding: 20px; background: #d4edda; border-radius: 8px; border: 1px solid #c3e6cb;">
      <h2>🎉 ナビゲーションテスト成功！</h2>
      <p>✅ ルーター navigation が動作しています</p>
      <p>✅ コンポーネントのマウントが成功しています</p>
      <p>✅ 認証が正常に動作しています</p>
      <p>✅ /history パスへのアクセスが成功しています</p>
    </div>
    
    <div style="margin-top: 20px; padding: 20px; background: #fff3cd; border-radius: 8px; border: 1px solid #ffeaa7;">
      <h3>📋 次のステップ</h3>
      <p>このSimpleHistoryViewが表示されている場合、問題は元のHistoryView.vueコンポーネントにあります。</p>
      <p>元のHistoryViewに戻すには「元のHistoryViewに戻る」ボタンをクリックしてください。</p>
    </div>
    
    <div style="margin-top: 20px; display: flex; gap: 10px; flex-wrap: wrap;">
      <button @click="goBack" style="padding: 10px 20px; background: #007bff; color: white; border: none; border-radius: 4px; cursor: pointer;">
        ← 戻る
      </button>
      <button @click="goToFixedHistory" style="padding: 10px 20px; background: #28a745; color: white; border: none; border-radius: 4px; cursor: pointer;">
        修正版HistoryView
      </button>
      <button @click="goToOriginalHistory" style="padding: 10px 20px; background: #dc3545; color: white; border: none; border-radius: 4px; cursor: pointer;">
        元のHistoryView (問題版)
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()
const currentTime = ref('')

const updateTime = () => {
  currentTime.value = new Date().toLocaleString()
}

const goBack = () => {
  router.back()
}

const goToFixedHistory = () => {
  console.log('Switching to fixed HistoryView...')
  // 現在のURLを /history に変更することで、FixedHistoryViewにアクセス
  window.location.href = '/history'
}

const goToOriginalHistory = () => {
  console.log('Switching to original HistoryView...')
  router.push('/history-original')
}

onMounted(() => {
  console.log('SimpleHistoryView mounted successfully!')
  updateTime()
  setInterval(updateTime, 1000)
})
</script>