import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import { Team, ApiError } from '../../types';
import { apiClient } from '../../api/client';

interface TeamState {
    teams: Team[];
    currentTeam: Team | null;
    loading: boolean;
    error: string | null;
}

const initialState: TeamState = {
    teams: [],
    currentTeam: null,
    loading: false,
    error: null,
};

export const createTeam = createAsyncThunk<
    Team,
    {
        name: string;
        description?: string;
    },
    { rejectValue: ApiError }
>('team/createTeam', async (data, { rejectWithValue }) => {
    try {
        return await apiClient.createTeam(data);
    } catch (error: any) {
        return rejectWithValue({
            error: error.response?.data?.error || '팀 생성 실패',
            status: error.response?.status
        });
    }
});

export const getTeams = createAsyncThunk<
    Team[],
    void,
    { rejectValue: ApiError }
>('team/getTeams', async (_, { rejectWithValue }) => {
    try {
        return await apiClient.getTeams();
    } catch (error: any) {
        return rejectWithValue({
            error: error.response?.data?.error || '팀 목록 조회 실패',
            status: error.response?.status
        });
    }
});


export const getTeam = createAsyncThunk<
    Team,
    number,
    { rejectValue: ApiError }
>('team/getTeam', async (id, { rejectWithValue }) => {
    try {
        return await apiClient.getTeam(id);
    } catch (error: any) {
        return rejectWithValue({
            error: error.response?.data?.error || '팀 조회 실패',
            status: error.response?.status
        });
    }
});

export const inviteToTeam = createAsyncThunk<
    void,
    {
        teamId: number;
        email: string;
        role: 'admin' | 'member' | 'viewer';
    },
    { rejectValue: ApiError }
>('team/inviteToTeam', async (data, { rejectWithValue }) => {
    try {
        await apiClient.inviteToTeam(data.teamId, {
            email: data.email,
            role: data.role,
        });
    } catch (error: any) {
        return rejectWithValue({
            error: error.response?.data?.error || '팀 초대 실패',
            status: error.response?.status
        });
    }
});

const teamSlice = createSlice({
    name: 'team',
    initialState,
    reducers: {
        clearError: (state) => {
            state.error = null;
        },
        clearCurrentTeam: (state) => {
            state.currentTeam = null;
        },
    },
    extraReducers: (builder) => {
        // Create Team
        builder.addCase(createTeam.pending, (state) => {
            state.loading = true;
            state.error = null;
        });
        builder.addCase(createTeam.fulfilled, (state, action) => {
            state.loading = false;
            state.teams.push(action.payload);
            state.currentTeam = action.payload;
        });
        builder.addCase(createTeam.rejected, (state, action) => {
            state.loading = false;
            state.error = action.payload?.error || '알 수 없는 오류가 발생했습니다';
        });

        // Get Team
        builder.addCase(getTeam.pending, (state) => {
            state.loading = true;
            state.error = null;
        });
        builder.addCase(getTeam.fulfilled, (state, action) => {
            state.loading = false;
            state.currentTeam = action.payload;
            const index = state.teams.findIndex(t => t.id === action.payload.id);
            if (index !== -1) {
                state.teams[index] = action.payload;
            } else {
                state.teams.push(action.payload);
            }
        });
        builder.addCase(getTeam.rejected, (state, action) => {
            state.loading = false;
            state.error = action.payload?.error || '알 수 없는 오류가 발생했습니다';
        });
        // Get Teams
        builder.addCase(getTeams.pending, (state) => {
            state.loading = true;
            state.error = null;
        });
        builder.addCase(getTeams.fulfilled, (state, action) => {
            state.loading = false;
            state.teams = action.payload;
        });
        builder.addCase(getTeams.rejected, (state, action) => {
            state.loading = false;
            state.error = action.payload?.error || '알 수 없는 오류가 발생했습니다';
        });

        // Invite to Team
        builder.addCase(inviteToTeam.pending, (state) => {
            state.loading = true;
            state.error = null;
        });
        builder.addCase(inviteToTeam.fulfilled, (state) => {
            state.loading = false;
        });
        builder.addCase(inviteToTeam.rejected, (state, action) => {
            state.loading = false;
            state.error = action.payload?.error || '알 수 없는 오류가 발생했습니다';
        });
    },
});

export const { clearError, clearCurrentTeam } = teamSlice.actions;
export default teamSlice.reducer; 