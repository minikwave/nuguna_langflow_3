import { Notification, ApiError } from '@/types/api';

export interface ApiClientConfig {
    baseURL: string;
    timeout?: number;
    headers?: Record<string, string>;
}

export interface ApiClientInterface {
    getNotifications(params?: {
        page?: number;
        per_page?: number;
        unread_only?: boolean;
    }): Promise<{ notifications: Notification[]; total: number }>;
    markNotificationAsRead(id: number): Promise<void>;
    markAllNotificationsAsRead(): Promise<void>;
} 