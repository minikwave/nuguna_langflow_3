import { configureStore } from '@reduxjs/toolkit';
import authReducer from './slices/authSlice';
import promptReducer from './slices/promptSlice';
import notificationReducer from './slices/notificationSlice';
import teamReducer from './slices/teamSlice';
import { AuthState, PromptState, NotificationState, TeamState } from './types';

export const store = configureStore({
    reducer: {
        auth: authReducer,
        prompt: promptReducer,
        notification: notificationReducer,
        team: teamReducer,
    },
    middleware: (getDefaultMiddleware) =>
        getDefaultMiddleware({
            serializableCheck: {
                // Ignore these action types
                ignoredActions: ['notification/connect', 'notification/disconnect'],
                // Ignore these field paths in all actions
                ignoredActionPaths: ['payload.websocket'],
                // Ignore these paths in the state
                ignoredPaths: ['notification.websocket'],
            },
        }),
});

export interface RootState {
    auth: AuthState;
    prompt: PromptState;
    notification: NotificationState;
    team: TeamState;
}

export type AppDispatch = typeof store.dispatch; 