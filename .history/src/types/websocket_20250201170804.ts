export interface NotificationWebSocket {
  connect(): void;
  disconnect(): void;
  on(type: string, handler: (data: any) => void): void;
  off(type: string, handler: (data: any) => void): void;
  send(data: any): void;
}

export interface WebSocketMessage {
  type: string;
  payload: any;
}

export enum WebSocketStatus {
  CONNECTING = 'CONNECTING',
  CONNECTED = 'CONNECTED',
  DISCONNECTED = 'DISCONNECTED',
  ERROR = 'ERROR'
} 