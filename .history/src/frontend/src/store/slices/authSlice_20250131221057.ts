import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import { User, AuthResponse, ApiError } from '../../types';
import { apiClient } from '../../api/client';

interface AuthState {
    user: User | null;
    token: string | null;
    loading: boolean;
    error: string | null;
}

const initialState: AuthState = {
    user: null,
    token: localStorage.getItem('token'),
    loading: false,
    error: null,
};

export const login = createAsyncThunk<
    AuthResponse,
    { email: string; password: string },
    { rejectValue: ApiError }
>('auth/login', async (credentials, { rejectWithValue }) => {
    try {
        const response = await apiClient.login(credentials.email, credentials.password);
        localStorage.setItem('token', response.access_token);
        return response;
    } catch (error: any) {
        return rejectWithValue({
            error: error.response?.data?.error || '로그인 실패',
            status: error.response?.status
        });
    }
});

export const register = createAsyncThunk<
    AuthResponse,
    {
        email: string;
        password: string;
        username: string;
        full_name?: string;
    },
    { rejectValue: ApiError }
>('auth/register', async (data, { rejectWithValue }) => {
    try {
        const response = await apiClient.register(data);
        localStorage.setItem('token', response.access_token);
        return response;
    } catch (error: any) {
        return rejectWithValue({
            error: error.response?.data?.error || '회원가입 실패',
            status: error.response?.status
        });
    }
});

export const getCurrentUser = createAsyncThunk<
    User,
    void,
    { rejectValue: ApiError }
>('auth/getCurrentUser', async (_, { rejectWithValue }) => {
    try {
        return await apiClient.getCurrentUser();
    } catch (error: any) {
        return rejectWithValue({
            error: error.response?.data?.error || '사용자 정보 조회 실패',
            status: error.response?.status
        });
    }
});

const authSlice = createSlice({
    name: 'auth',
    initialState,
    reducers: {
        logout: (state) => {
            state.user = null;
            state.token = null;
            state.error = null;
            localStorage.removeItem('token');
        },
        clearError: (state) => {
            state.error = null;
        },
    },
    extraReducers: (builder) => {
        // Login
        builder.addCase(login.pending, (state) => {
            state.loading = true;
            state.error = null;
        });
        builder.addCase(login.fulfilled, (state, action) => {
            state.loading = false;
            state.user = action.payload.user;
            state.token = action.payload.access_token;
        });
        builder.addCase(login.rejected, (state, action) => {
            state.loading = false;
            state.error = action.payload?.error || '알 수 없는 오류가 발생했습니다';
        });

        // Register
        builder.addCase(register.pending, (state) => {
            state.loading = true;
            state.error = null;
        });
        builder.addCase(register.fulfilled, (state, action) => {
            state.loading = false;
            state.user = action.payload.user;
            state.token = action.payload.access_token;
        });
        builder.addCase(register.rejected, (state, action) => {
            state.loading = false;
            state.error = action.payload?.error || '알 수 없는 오류가 발생했습니다';
        });

        // Get Current User
        builder.addCase(getCurrentUser.pending, (state) => {
            state.loading = true;
            state.error = null;
        });
        builder.addCase(getCurrentUser.fulfilled, (state, action) => {
            state.loading = false;
            state.user = action.payload;
        });
        builder.addCase(getCurrentUser.rejected, (state, action) => {
            state.loading = false;
            state.error = action.payload?.error || '알 수 없는 오류가 발생했습니다';
        });
    },
});

export const { logout, clearError } = authSlice.actions;
export default authSlice.reducer; 