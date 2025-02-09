import { configureStore } from '@reduxjs/toolkit';
import { setupListeners } from '@reduxjs/toolkit/query';
import { langflowApi } from '../services/langflow';
import { sqlApi } from '../services/sql';
import errorReducer from './slices/errorSlice';
import loadingReducer from './slices/loadingSlice';
import sessionReducer from './slices/sessionSlice';

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
            serializableCheck: false,
            immutableCheck: false,
        }).concat(langflowApi.middleware, sqlApi.middleware),
    devTools: process.env.NODE_ENV !== 'production',
});

setupListeners(store.dispatch);

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch; 