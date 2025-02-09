import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import type { PayloadAction } from '@reduxjs/toolkit';
import { 
    Notification, 
    ApiError, 
    NotificationState,
    RootState 
} from '@/types';
import { apiClient } from '@/api/client';
import { NotificationWebSocket } from '@/websocket';
import { WS_CONFIG } from '@/config/websocket';

// ... 나머지 코드는 동일 