import { User, Prompt, Team, Notification } from '../types';

export interface AuthState {
    user: User | null;
    token: string | null;
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
    websocket: any | null;
    connected: boolean;
}

export interface TeamState {
    teams: Team[];
    currentTeam: Team | null;
    loading: boolean;
    error: string | null;
} 