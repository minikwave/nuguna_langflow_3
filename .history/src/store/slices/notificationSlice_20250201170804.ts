import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import type { PayloadAction } from '@reduxjs/toolkit';
import { Notification, ApiError } from '@/types/api';
import { WebSocketStatus } from '@/types/websocket';
import { NotificationWebSocket } from '@/websocket';
import type { RootState } from '@/store/types';
import { apiClient } from '@/api/client';

// ... 나머지 코드는 동일 