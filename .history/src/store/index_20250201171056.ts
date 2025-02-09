import { configureStore } from '@reduxjs/toolkit';
import authReducer from './slices/authSlice';
import notificationReducer from './slices/notificationSlice';
import evaluationReducer from './slices/evaluationSlice';
import { RootState } from '@/types';

export const store = configureStore({
    reducer: {
        auth: authReducer,
        notification: notificationReducer,
        evaluation: evaluationReducer,
    },
});

export type AppDispatch = typeof store.dispatch;
export type { RootState }; 