/* eslint-disable */
/* tslint:disable */
// @ts-nocheck
/*
 * ---------------------------------------------------------------
 * ## THIS FILE WAS GENERATED VIA SWAGGER-TYPESCRIPT-API        ##
 * ##                                                           ##
 * ## AUTHOR: acacode                                           ##
 * ## SOURCE: https://github.com/acacode/swagger-typescript-api ##
 * ---------------------------------------------------------------
 */

export enum ModelsMessageStatus {
  /** 下書き */
  MessageStatusDraft = "draft",
  /** AI変換中 */
  MessageStatusProcessing = "processing",
  /** 送信予約済み */
  MessageStatusScheduled = "scheduled",
  /** 送信完了 */
  MessageStatusSent = "sent",
  /** 配信完了 */
  MessageStatusDelivered = "delivered",
  /** 既読 */
  MessageStatusRead = "read",
}

export interface ModelsCreateMessageRequest {
  /** @maxLength 1000 */
  originalText?: string;
  /** @maxLength 500 */
  reason?: string;
  recipientEmail?: string;
}

export interface ModelsGetSentMessagesResponse {
  data?: {
    messages?: ModelsMessageWithRecipientInfo[];
    pagination?: ModelsPaginationResponse;
  };
  message?: string;
}

export interface ModelsMessage {
  createdAt?: string;
  deliveredAt?: string;
  finalText?: string;
  id?: string;
  originalText?: string;
  readAt?: string;
  reason?: string;
  recipientId?: string;
  scheduledAt?: string;
  selectedTone?: string;
  senderId?: string;
  sentAt?: string;
  status?: ModelsMessageStatus;
  updatedAt?: string;
  variations?: ModelsMessageVariations;
}

export interface ModelsMessageResponse {
  data?: ModelsMessage;
  message?: string;
}

export interface ModelsMessageVariations {
  casual?: string;
  constructive?: string;
  gentle?: string;
}

export interface ModelsMessageWithRecipientInfo {
  createdAt?: string;
  deliveredAt?: string;
  finalText?: string;
  id?: string;
  originalText?: string;
  readAt?: string;
  reason?: string;
  recipientEmail?: string;
  recipientId?: string;
  recipientName?: string;
  scheduledAt?: string;
  selectedTone?: string;
  senderId?: string;
  sentAt?: string;
  status?: ModelsMessageStatus;
  updatedAt?: string;
  variations?: ModelsMessageVariations;
}

export interface ModelsPaginationResponse {
  limit?: number;
  page?: number;
  total?: number;
}
