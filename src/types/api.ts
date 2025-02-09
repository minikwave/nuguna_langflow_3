export interface ApiError {
    error: string;
    status: number;
}

export interface ErrorResponse {
    message: string;
    code: string;
    details?: Record<string, any>;
}

export interface Notification {
    id: number;
    type: string;
    content: string;
    is_read: boolean;
    created_at: string;
    data?: any;
    status?: string;
}

export interface NotificationResponse {
    notifications: Notification[];
    total: number;
} 