import { User, Prompt, Team, Notification } from '../types';

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

export interface PromptState {
    prompts: Prompt[];
    currentPrompt: Prompt | null;
    versions: any[];
    comments: any[];
    loading: boolean;
    error: string | null;
    totalPages: number;
    currentPage: number;
}

export interface NotificationState {
    notifications: Notification[];
    unreadCount: number;
    loading: boolean;
    error: string | null;
    websocket: WebSocket | null;
    connected: boolean;
    filters: NotificationFilters;
}

export interface TeamState {
    teams: Team[];
    currentTeam: Team | null;
    loading: boolean;
    error: string | null;
}

export interface EvaluationState {
    results: EvaluationResult[];
    loading: boolean;
    error: string | null;
    currentPage: number;
    totalPages: number;
} 