import axios, { AxiosInstance, AxiosResponse, AxiosError } from 'axios';
import { AuthResponse, ApiError } from '../types';
import { store } from '@/store';
import { logout } from '@/store/slices/authSlice';


export class ApiClient {
    private client: AxiosInstance;
    private static instance: ApiClient;

    private constructor() {
        this.client = axios.create({
            baseURL: process.env.NEXT_PUBLIC_API_URL,
            timeout: 10000,
            headers: {
                'Content-Type': 'application/json'
            }
        });

        this.setupInterceptors();
    }

    private setupInterceptors(): void {
        this.client.interceptors.request.use(
            config => {
                const token = store.getState().auth.token;
                if (token) {
                    config.headers.Authorization = `Bearer ${token}`;
                }
                return config;
            }
        );

        this.client.interceptors.response.use(
            response => response,
            (error: AxiosError) => {
                if (error.response?.status === 401) {
                    store.dispatch(logout());
                }
                return Promise.reject(error);
            }
        );
    }

    public static getInstance(): ApiClient {
        if (!ApiClient.instance) {
            ApiClient.instance = new ApiClient();
        }
        return ApiClient.instance;
    }

    private handleError(error: any) {
        const errorResponse = {
            error: error.response?.data?.error || '알 수 없는 오류가 발생했습니다',
            status: error.response?.status
        };
        // 에러 로깅 추가
        console.error('[API Error]', errorResponse);
        return errorResponse;
    }

    // 인증 관련 API
    public async login(email: string, password: string): Promise<AuthResponse> {
        const response = await this.client.post<AuthResponse>('/auth/login', {
            email,
            password
        });
        return response.data;
    }

    public async register(data: {
        email: string;
        password: string;
        username: string;
        full_name?: string;
    }): Promise<AuthResponse> {
        const response = await this.client.post<AuthResponse>('/auth/register', data);
        return response.data;
    }

    public async getCurrentUser() {
        const response = await this.client.get('/auth/me');
        return response.data;
    }

    // 프롬프트 관련 API
    public async getPrompts(params?: {
        query?: string;
        tags?: string[];
        user_id?: number;
        team_id?: number;
    }) {
        const response = await this.client.get('/prompts', { params });
        return response.data;
    }

    public async getPrompt(id: number) {
        const response = await this.client.get(`/prompts/${id}`);
        return response.data;
    }

    public async createPrompt(data: {
        title: string;
        description: string;
        content: string;
        expected_sql?: string;
        team_id?: number;
        tags?: string[];
    }) {
        const response = await this.client.post('/prompts', data);
        return response.data;
    }

    public async updatePrompt(id: number, data: {
        content: string;
        expected_sql?: string;
        changelog?: string;
    }) {
        const response = await this.client.post(`/prompts/${id}/versions`, data);
        return response.data;
    }

    // 평가 관련 API
    public async evaluatePrompt(data: {
        flow_id: string;
        prompt: string;
        expected_sql: string;
        test_cases?: any[];
    }) {
        const response = await this.client.post('/evaluate', data);
        return response.data;
    }

    // 알림 관련 API
    public async getNotifications(params?: {
        page?: number;
        per_page?: number;
        unread_only?: boolean;
    }) {
        const response = await this.client.get('/notifications', { params });
        return response.data;
    }

    public async markNotificationAsRead(id: number) {
        const response = await this.client.post(`/notifications/${id}/read`);
        return response.data;
    }

    public async markAllNotificationsAsRead() {
        const response = await this.client.post('/notifications/read-all');
        return response.data;
    }

    // 팀 관련 API
    public async createTeam(data: {
        name: string;
        description?: string;
    }) {
        const response = await this.client.post('/teams', data);
        return response.data;
    }

    public async getTeam(id: number) {
        const response = await this.client.get(`/teams/${id}`);
        return response.data;
    }

    public async getTeams() {
        const response = await this.client.get('/teams');
        return response.data;
    }

    public async inviteToTeam(teamId: number, data: {
        email: string;

        role: 'admin' | 'member' | 'viewer';
    }) {
        const response = await this.client.post(`/teams/${teamId}/invite`, data);
        return response.data;
    }
}

export const apiClient = ApiClient.getInstance(); 