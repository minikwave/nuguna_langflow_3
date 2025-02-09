import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import { Prompt, PromptVersion, Comment, ApiError } from '../../types';
import { apiClient } from '../../api/client';

interface PromptState {
    prompts: Prompt[];
    currentPrompt: Prompt | null;
    versions: PromptVersion[];
    comments: Comment[];
    loading: boolean;
    error: string | null;
    totalPages: number;
    currentPage: number;
}

const initialState: PromptState = {
    prompts: [],
    currentPrompt: null,
    versions: [],
    comments: [],
    loading: false,
    error: null,
    totalPages: 1,
    currentPage: 1,
};

export const getPrompts = createAsyncThunk<
    { prompts: Prompt[]; total_pages: number },
    { page?: number; query?: string; tags?: string[]; user_id?: number; team_id?: number } | void,
    { rejectValue: ApiError }
>('prompt/getPrompts', async (params, { rejectWithValue }) => {
    try {
        return await apiClient.getPrompts(params);
    } catch (error: any) {
        return rejectWithValue({
            error: error.response?.data?.error || '프롬프트 목록 조회 실패',
            status: error.response?.status
        });
    }
});

export const getPrompt = createAsyncThunk<
    Prompt,
    number,
    { rejectValue: ApiError }
>('prompt/getPrompt', async (id, { rejectWithValue }) => {
    try {
        return await apiClient.getPrompt(id);
    } catch (error: any) {
        return rejectWithValue({
            error: error.response?.data?.error || '프롬프트 조회 실패',
            status: error.response?.status
        });
    }
});

export const createPrompt = createAsyncThunk<
    Prompt,
    {
        title: string;
        description: string;
        content: string;
        expected_sql?: string;
        team_id?: number;
        tags?: string[];
    },
    { rejectValue: ApiError }
>('prompt/createPrompt', async (data, { rejectWithValue }) => {
    try {
        return await apiClient.createPrompt(data);
    } catch (error: any) {
        return rejectWithValue({
            error: error.response?.data?.error || '프롬프트 생성 실패',
            status: error.response?.status
        });
    }
});

export const updatePrompt = createAsyncThunk<
    PromptVersion,
    {
        id: number;
        content: string;
        expected_sql?: string;
        changelog?: string;
    },
    { rejectValue: ApiError }
>('prompt/updatePrompt', async (data, { rejectWithValue }) => {
    try {
        return await apiClient.updatePrompt(data.id, {
            content: data.content,
            expected_sql: data.expected_sql,
            changelog: data.changelog,
        });
    } catch (error: any) {
        return rejectWithValue({
            error: error.response?.data?.error || '프롬프트 업데이트 실패',
            status: error.response?.status
        });
    }
});

const promptSlice = createSlice({
    name: 'prompt',
    initialState,
    reducers: {
        clearError: (state) => {
            state.error = null;
        },
        clearCurrentPrompt: (state) => {
            state.currentPrompt = null;
            state.versions = [];
            state.comments = [];
        },
    },
    extraReducers: (builder) => {
        // Get Prompts
        builder.addCase(getPrompts.pending, (state) => {
            state.loading = true;
            state.error = null;
        });
        builder.addCase(getPrompts.fulfilled, (state, action) => {
            state.loading = false;
            state.prompts = action.payload.prompts;
            state.totalPages = action.payload.total_pages;
        });
        builder.addCase(getPrompts.rejected, (state, action) => {
            state.loading = false;
            state.error = action.payload?.error || '알 수 없는 오류가 발생했습니다';
        });

        // Get Prompt
        builder.addCase(getPrompt.pending, (state) => {
            state.loading = true;
            state.error = null;
        });
        builder.addCase(getPrompt.fulfilled, (state, action) => {
            state.loading = false;
            state.currentPrompt = action.payload;
            if (action.payload.versions) {
                state.versions = action.payload.versions;
            }
        });
        builder.addCase(getPrompt.rejected, (state, action) => {
            state.loading = false;
            state.error = action.payload?.error || '알 수 없는 오류가 발생했습니다';
        });

        // Create Prompt
        builder.addCase(createPrompt.pending, (state) => {
            state.loading = true;
            state.error = null;
        });
        builder.addCase(createPrompt.fulfilled, (state, action) => {
            state.loading = false;
            state.prompts.unshift(action.payload);
        });
        builder.addCase(createPrompt.rejected, (state, action) => {
            state.loading = false;
            state.error = action.payload?.error || '알 수 없는 오류가 발생했습니다';
        });

        // Update Prompt
        builder.addCase(updatePrompt.pending, (state) => {
            state.loading = true;
            state.error = null;
        });
        builder.addCase(updatePrompt.fulfilled, (state, action) => {
            state.loading = false;
            if (state.currentPrompt) {
                state.versions.unshift(action.payload);
            }
        });
        builder.addCase(updatePrompt.rejected, (state, action) => {
            state.loading = false;
            state.error = action.payload?.error || '알 수 없는 오류가 발생했습니다';
        });
    },
});

export const { clearError, clearCurrentPrompt } = promptSlice.actions;
export default promptSlice.reducer; 