import { config } from '@/config';

export const WS_CONFIG = {
    BASE_URL: config.WS_URL,
    RECONNECT_ATTEMPTS: 5,
    RECONNECT_DELAY: 1000,
    PING_INTERVAL: 30000,
}; 