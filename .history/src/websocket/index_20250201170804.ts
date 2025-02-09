import { NotificationWebSocket as INotificationWebSocket, WebSocketMessage } from '@/types/websocket';

export class NotificationWebSocket implements INotificationWebSocket {
    private token: string;
    private ws: WebSocket | null;
    private reconnectAttempts: number;
    private readonly maxReconnectAttempts: number;
    private readonly reconnectDelay: number;
    private handlers: Map<string, Set<(data: any) => void>>;

    constructor(token: string) {
        this.token = token;
        this.ws = null;
        this.reconnectAttempts = 0;
        this.maxReconnectAttempts = 5;
        this.reconnectDelay = 1000;
        this.handlers = new Map();
    }

    connect(): void {
        const wsUrl = `${process.env.NEXT_PUBLIC_WS_URL}/ws/${this.token}`;
        this.ws = new WebSocket(wsUrl);

        this.ws.onopen = () => {
            console.log('WebSocket connected');
            this.reconnectAttempts = 0;
        };

        this.ws.onmessage = (event: MessageEvent) => {
            const message: WebSocketMessage = JSON.parse(event.data);
            this._handleMessage(message);
        };

        this.ws.onclose = () => {
            console.log('WebSocket disconnected');
            this._reconnect();
        };

        this.ws.onerror = (error: Event) => {
            console.error('WebSocket error:', error);
        };
    }

    disconnect(): void {
        if (this.ws) {
            this.ws.close();
            this.ws = null;
        }
    }

    on(type: string, handler: (data: any) => void): void {
        if (!this.handlers.has(type)) {
            this.handlers.set(type, new Set());
        }
        this.handlers.get(type)?.add(handler);
    }

    off(type: string, handler: (data: any) => void): void {
        this.handlers.get(type)?.delete(handler);
    }

    send(data: any): void {
        if (this.ws && this.ws.readyState === WebSocket.OPEN) {
            this.ws.send(JSON.stringify(data));
        }
    }

    private _handleMessage(message: WebSocketMessage): void {
        const handlers = this.handlers.get(message.type);
        if (handlers) {
            handlers.forEach(handler => handler(message.payload));
        }
    }

    private _reconnect(): void {
        if (this.reconnectAttempts >= this.maxReconnectAttempts) {
            console.error('Max reconnection attempts reached');
            return;
        }

        this.reconnectAttempts++;
        const delay = this.reconnectDelay * Math.pow(2, this.reconnectAttempts - 1);

        console.log(`Reconnecting in ${delay}ms...`);
        setTimeout(() => this.connect(), delay);
    }
}

export default NotificationWebSocket; 