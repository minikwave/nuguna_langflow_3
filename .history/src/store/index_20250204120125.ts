import { configureStore, ThunkAction, Action } from '@reduxjs/toolkit';
import { setupListeners } from '@reduxjs/toolkit/query/react';
import { TypedUseSelectorHook, useDispatch, useSelector } from 'react-redux';
import { langflowApi } from '../services/api/langflow';
import { sqlApi } from '../services/api/sql';
import errorReducer from './slices/error';
import loadingReducer from './slices/loading';
import sessionReducer from './slices/session';

// 스토어 설정
export const store = configureStore({
    reducer: {
        [langflowApi.reducerPath]: langflowApi.reducer,
        [sqlApi.reducerPath]: sqlApi.reducer,
        error: errorReducer,
        loading: loadingReducer,
        session: sessionReducer,
    },
    middleware: (getDefaultMiddleware) =>
        getDefaultMiddleware({
            serializableCheck: {
                ignoredActions: ['persist/PERSIST'],
                ignoredPaths: ['register.timestamp'],
            },
            immutableCheck: { warnAfter: 128 },
        }).concat(langflowApi.middleware, sqlApi.middleware),
    devTools: process.env.NODE_ENV !== 'production',
});

// 리스너 설정
setupListeners(store.dispatch);

// 타입 정의
export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
export type AppThunk<ReturnType = void> = ThunkAction<
    ReturnType,
    RootState,
    unknown,
    Action<string>
>;

// 커스텀 훅
export const useAppDispatch = () => useDispatch<AppDispatch>();
export const useAppSelector: TypedUseSelectorHook<RootState> = useSelector; 