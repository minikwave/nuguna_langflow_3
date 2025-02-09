export class ApiCache {
    private static instance: ApiCache;
    private cache: Map<string, {
        data: any,
        timestamp: number,
        ttl: number
    }>;

    private constructor() {
        this.cache = new Map();
    }

    static getInstance() {
        if (!ApiCache.instance) {
            ApiCache.instance = new ApiCache();
        }
        return ApiCache.instance;
    }

    get(key: string): any {
        const cached = this.cache.get(key);
        if (cached && Date.now() - cached.timestamp < cached.ttl) {
            return cached.data;
        }
        return null;
    }

    set(key: string, data: any, ttl: number = 5 * 60 * 1000) {
        this.cache.set(key, {
            data,
            timestamp: Date.now(),
            ttl
        });
    }
} 