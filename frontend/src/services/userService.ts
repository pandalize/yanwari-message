import { apiService } from './api'

export interface User {
  id: string
  name: string
  email: string
  createdAt?: string
}

export interface UserSearchResponse {
  data: {
    users: User[]
    pagination: {
      page: number
      limit: number
      total: number
    }
  }
}

class UserService {
  async searchUsers(query: string, limit = 10): Promise<UserSearchResponse> {
    const response = await apiService.api.get(`/users/search?q=${encodeURIComponent(query)}&limit=${limit}`)
    return response.data
  }

  async getUserByEmail(email: string): Promise<{ data: User }> {
    const response = await apiService.api.get(`/users/by-email?email=${encodeURIComponent(email)}`)
    return response.data
  }
}

export const userService = new UserService()