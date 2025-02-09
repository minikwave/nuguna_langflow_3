export interface User {
    id: number;
    email: string;
    username: string;
    full_name?: string;
    is_superuser: boolean;
    created_at: string;
    last_login?: string;
}

export interface Prompt {
    id: number;
    title: string;
    description: string;
    owner: {
        id: number;
        username: string;
    };
    team?: {
        id: number;
        name: string;
    };
    tags: string[];
    latest_version?: PromptVersion;
    created_at: string;
    updated_at: string;
}

export interface PromptVersion {
    number: number;
    content: string;
    expected_sql?: string;
    changelog?: string;
    creator: {
        id: number;
        username: string;
    };
    created_at: string;
    metrics: {
        accuracy: number;
        execution_time: number;
        success_rate: number;
    };
}

export interface Comment {
    id: number;
    content: string;
    author: {
        id: number;
        username: string;
    };
    created_at: string;
    updated_at: string;
    prompt_version_id?: number;
    parent_id?: number;
    replies?: Comment[];
}

export interface Team {
    id: number;
    name: string;
    description?: string;
    created_at: string;
    members: TeamMember[];
}

export interface TeamMember {
    id: number;
    user: {
        id: number;
        username: string;
    };
    role: 'admin' | 'member' | 'viewer';
    joined_at: string;
}

export interface Notification {
    id: number;
    type: 'comment' | 'version' | 'mention' | 'team_invite';
    content: string;
    data?: any;
    is_read: boolean;
    created_at: string;
}

export interface EvaluationResult {
    prompt: string;
    generated_sql?: string;
    expected_sql?: string;
    execution_time?: number;
    sql_accuracy?: number;
    test_results?: TestResult[];
    error?: string;
    timestamp: string;
}

export interface TestResult {
    test_case: any;
    success: boolean;
    actual_result?: any;
    error?: string;
}

export interface AuthResponse {
    access_token: string;
    token_type: string;
    user: User;
}

export interface ApiError {
    error: string;
    status?: number;
} 