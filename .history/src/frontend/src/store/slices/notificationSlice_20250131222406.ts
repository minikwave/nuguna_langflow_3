import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import { Notification, ApiError } from '../../types';
import { apiClient } from '../../api/client';
import { NotificationWebSocket } from '../../websocket';

interface NotificationState {
    notifications: Notification[];
    unreadCount: number;
    loading: boolean;
    error: string | null;
    websocket: NotificationWebSocket | null;
    connected: boolean;
}

const initialState: NotificationState = {
    notifications: [],
    unreadCount: 0,
    loading: false,
    error: null,
    websocket: null,
    connected: false,
};

export const getNotifications = createAsyncThunk<
    { notifications: Notification[]; total: number },
    { page?: number; per_page?: number; unread_only?: boolean } | void,
    { rejectValue: ApiError }
>('notification/getNotifications', async (params, { rejectWithValue }) => {
    try {
        return await apiClient.getNotifications(params);
    } catch (error: any) {
        return rejectWithValue({
            error: error.response?.data?.error || '알림 조회 실패',
            status: error.response?.status
        });
    }
});

export const markAsRead = createAsyncThunk<
    void,
    number,
    { rejectValue: ApiError }
>('notification/markAsRead', async (id, { rejectWithValue }) => {
    try {
        await apiClient.markNotificationAsRead(id);
    } catch (error: any) {
        return rejectWithValue({
            error: error.response?.data?.error || '알림 상태 변경 실패',
            status: error.response?.status
        });
    }
});

export const markAllAsRead = createAsyncThunk<
    void,
    void,
    { rejectValue: ApiError }
>('notification/markAllAsRead', async (_, { rejectWithValue }) => {
    try {
        await apiClient.markAllNotificationsAsRead();
    } catch (error: any) {
        return rejectWithValue({
            error: error.response?.data?.error || '알림 상태 변경 실패',
            status: error.response?.status
        });
    }
});

const notificationSlice = createSlice({
    name: 'notification',
    initialState,
    reducers: {
        connect: (state, action) => {
            state.websocket = action.payload;
            state.connected = true;
        },
        disconnect: (state) => {
            if (state.websocket) {
                state.websocket.disconnect();
            }
            state.websocket = null;
            state.connected = false;
        },
        addNotification: (state, action) => {
            state.notifications.unshift(action.payload);
            if (!action.payload.is_read) {
                state.unreadCount++;
            }
        },
        clearError: (state) => {
            state.error = null;
        },
    },
    extraReducers: (builder) => {
        // Get Notifications
        builder.addCase(getNotifications.pending, (state) => {
            state.loading = true;
            state.error = null;
        });
        builder.addCase(getNotifications.fulfilled, (state, action) => {
            state.loading = false;
            state.notifications = action.payload.notifications;
            state.unreadCount = action.payload.notifications.filter(n => !n.is_read).length;
        });
        builder.addCase(getNotifications.rejected, (state, action) => {
            state.loading = false;
            state.error = action.payload?.error || '알 수 없는 오류가 발생했습니다';
        });

        // Mark as Read
        builder.addCase(markAsRead.fulfilled, (state, action) => {
            const notification = state.notifications.find(n => n.id === action.meta.arg);
            if (notification && !notification.is_read) {
                notification.is_read = true;
                state.unreadCount--;
            }
        });

        // Mark All as Read
        builder.addCase(markAllAsRead.fulfilled, (state) => {
            state.notifications.forEach(n => {
                n.is_read = true;
            });
            state.unreadCount = 0;
        });
    },
});

export const {
    connect,
    disconnect,
    addNotification,
    clearError,
} = notificationSlice.actions;

export default notificationSlice.reducer; 