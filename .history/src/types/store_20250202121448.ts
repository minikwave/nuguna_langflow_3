import { EvaluationResult } from '@/frontend/src/types';
import { User } from '@/frontend/src/types';
import { Notification } from './api';
import { NotificationWebSocket } from '@/websocket';

export interface RootState {
    auth: AuthState;
    notification: NotificationState;
    evaluation: EvaluationState;
}

export interface AuthState {
    token: string | null;
    user: User | null;
    loading: boolean;
    error: string | null;
}

export interface NotificationState {
    notifications: Notification[];
    unreadCount: number;
    loading: boolean;
    error: string | null;
    websocket: NotificationWebSocket | null;
    connected: boolean;
    filters: {
        type: string | null;
        status: string | null;
    };
}

export interface EvaluationState {
    results: EvaluationResult[];
    loading: boolean;
    error: string | null;
    currentPage: number;
    totalPages: number;
} 