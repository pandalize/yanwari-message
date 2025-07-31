import type { InboxMessageWithRating } from '../services/ratingService'

// ツリーマップテスト用のモックデータ生成
export const generateMockMessages = (): InboxMessageWithRating[] => {
  const senders = [
    { name: '田中太郎', email: 'tanaka@example.com' },
    { name: '佐藤花子', email: 'sato@example.com' },
    { name: '山田次郎', email: 'yamada@example.com' },
    { name: '鈴木美咲', email: 'suzuki@example.com' },
    { name: '高橋健一', email: 'takahashi@example.com' },
    { name: '伊藤愛', email: 'ito@example.com' }
  ]

  const messageSamples = [
    'お疲れ様です！明日の会議の件でご相談があります。',
    'プロジェクトの進捗について確認させていただきたく。',
    '資料の共有をお願いいたします。',
    '来週のスケジュール調整をお願いします。',
    'システムの不具合について報告です。',
    '新しい提案があります。ご検討ください。',
    'お忙しい中恐縮ですが、確認をお願いします。',
    '月末の締切について相談があります。',
    'チームミーティングの件でご連絡です。',
    '予算についてご相談したいことがあります。'
  ]

  const messages: InboxMessageWithRating[] = []
  const now = new Date()

  // 過去3ヶ月のメッセージを生成
  for (let i = 0; i < 50; i++) {
    const sender = senders[Math.floor(Math.random() * senders.length)]
    const messageText = messageSamples[Math.floor(Math.random() * messageSamples.length)]
    
    // 日付を過去3ヶ月にランダム分散
    const daysAgo = Math.floor(Math.random() * 90)
    const messageDate = new Date(now.getTime() - daysAgo * 24 * 60 * 60 * 1000)
    
    // 評価は60%の確率で存在（1-5の範囲）
    const hasRating = Math.random() > 0.4
    const rating = hasRating ? Math.floor(Math.random() * 5) + 1 : undefined
    
    // ステータス（60%が既読、30%が未読、10%が配信済み）
    const statusRand = Math.random()
    const isRead = statusRand > 0.4
    const status = isRead ? 'read' : (statusRand > 0.1 ? 'delivered' : 'sent')
    
    const message: InboxMessageWithRating = {
      id: `msg_${i + 1}`,
      senderId: `user_${sender.email}`,
      senderName: sender.name,
      senderEmail: sender.email,
      originalText: messageText,
      finalText: messageText + ' 【やんわり変換済み】',
      status: status,
      rating: rating,
      ratingId: rating ? `rating_${i + 1}` : undefined,
      createdAt: messageDate.toISOString(),
      sentAt: messageDate.toISOString(),
      deliveredAt: messageDate.toISOString(),
      readAt: status === 'read' ? new Date(messageDate.getTime() + Math.random() * 24 * 60 * 60 * 1000).toISOString() : undefined
    }
    
    messages.push(message)
  }

  // 日付順にソート（新しい順）
  messages.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())

  return messages
}

// 評価分布を生成
export const generateRatingDistribution = (messages: InboxMessageWithRating[]) => {
  const distribution = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, unrated: 0 }
  
  messages.forEach(message => {
    if (message.rating) {
      distribution[message.rating as keyof typeof distribution]++
    } else {
      distribution.unrated++
    }
  })
  
  return distribution
}

// 送信者別統計を生成
export const generateSenderStats = (messages: InboxMessageWithRating[]) => {
  const stats: { [key: string]: any } = {}
  
  messages.forEach(message => {
    const key = message.senderName || message.senderEmail
    
    if (!stats[key]) {
      stats[key] = {
        name: message.senderName,
        email: message.senderEmail,
        messageCount: 0,
        totalRating: 0,
        ratedCount: 0,
        avgRating: 0,
        lastMessage: message.createdAt
      }
    }
    
    stats[key].messageCount++
    
    if (message.rating) {
      stats[key].totalRating += message.rating
      stats[key].ratedCount++
    }
    
    // より新しいメッセージの日付で更新
    if (new Date(message.createdAt) > new Date(stats[key].lastMessage)) {
      stats[key].lastMessage = message.createdAt
    }
  })
  
  // 平均評価を計算
  Object.values(stats).forEach((stat: any) => {
    if (stat.ratedCount > 0) {
      stat.avgRating = stat.totalRating / stat.ratedCount
    }
  })
  
  return stats
}

// 日付別統計を生成
export const generateDateStats = (messages: InboxMessageWithRating[]) => {
  const now = new Date()
  const stats = {
    thisWeek: { count: 0, totalRating: 0, ratedCount: 0 },
    thisMonth: { count: 0, totalRating: 0, ratedCount: 0 },
    last3Months: { count: 0, totalRating: 0, ratedCount: 0 },
    older: { count: 0, totalRating: 0, ratedCount: 0 }
  }
  
  messages.forEach(message => {
    const messageDate = new Date(message.createdAt)
    const diffDays = (now.getTime() - messageDate.getTime()) / (1000 * 60 * 60 * 24)
    
    let category: keyof typeof stats
    if (diffDays <= 7) category = 'thisWeek'
    else if (diffDays <= 30) category = 'thisMonth'
    else if (diffDays <= 90) category = 'last3Months'
    else category = 'older'
    
    stats[category].count++
    if (message.rating) {
      stats[category].totalRating += message.rating
      stats[category].ratedCount++
    }
  })
  
  return stats
}