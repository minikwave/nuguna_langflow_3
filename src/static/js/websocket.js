class NotificationWebSocket {
    constructor(token) {
        this.token = token;
        this.ws = null;
        this.reconnectAttempts = 0;
        this.maxReconnectAttempts = 5;
        this.reconnectDelay = 1000; // 1초
        this.handlers = new Map();
    }

    connect() {
        const wsUrl = `ws://${window.location.host}/api/ws/${this.token}`;
        this.ws = new WebSocket(wsUrl);

        this.ws.onopen = () => {
            console.log('WebSocket connected');
            this.reconnectAttempts = 0;
        };

        this.ws.onmessage = (event) => {
            const notification = JSON.parse(event.data);
            this._handleNotification(notification);
        };

        this.ws.onclose = (event) => {
            console.log('WebSocket disconnected:', event.code, event.reason);
            this._reconnect();
        };

        this.ws.onerror = (error) => {
            console.error('WebSocket error:', error);
        };
    }

    disconnect() {
        if (this.ws) {
            this.ws.close();
            this.ws = null;
        }
    }

    _reconnect() {
        if (this.reconnectAttempts >= this.maxReconnectAttempts) {
            console.error('Max reconnection attempts reached');
            return;
        }

        this.reconnectAttempts++;
        const delay = this.reconnectDelay * Math.pow(2, this.reconnectAttempts - 1);

        console.log(`Reconnecting in ${delay}ms...`);
        setTimeout(() => this.connect(), delay);
    }

    on(type, handler) {
        if (!this.handlers.has(type)) {
            this.handlers.set(type, new Set());
        }
        this.handlers.get(type).add(handler);
    }

    off(type, handler) {
        if (this.handlers.has(type)) {
            this.handlers.get(type).delete(handler);
        }
    }

    _handleNotification(notification) {
        // 기본 알림 처리
        this._showNotification(notification);

        // 타입별 핸들러 실행
        const handlers = this.handlers.get(notification.type);
        if (handlers) {
            handlers.forEach(handler => handler(notification));
        }
    }

    _showNotification(notification) {
        // 브라우저 알림 권한 요청
        if (Notification.permission !== 'granted') {
            Notification.requestPermission();
        }

        // 브라우저 알림 표시
        if (Notification.permission === 'granted') {
            new Notification(notification.content, {
                body: notification.data ? JSON.stringify(notification.data) : undefined,
                icon: '/static/img/notification-icon.png'
            });
        }

        // 화면 내 알림 표시
        const notificationElement = document.createElement('div');
        notificationElement.className = 'notification';
        notificationElement.innerHTML = `
            <div class="notification-content">
                <h4>${notification.type}</h4>
                <p>${notification.content}</p>
                ${notification.data ? `<pre>${JSON.stringify(notification.data, null, 2)}</pre>` : ''}
                <small>${new Date(notification.timestamp).toLocaleString()}</small>
            </div>
            <button class="notification-close">&times;</button>
        `;

        document.getElementById('notifications-container').appendChild(notificationElement);

        // 5초 후 자동으로 닫기
        setTimeout(() => {
            notificationElement.remove();
        }, 5000);

        // 닫기 버튼 이벤트
        notificationElement.querySelector('.notification-close').onclick = () => {
            notificationElement.remove();
        };
    }
}

// 사용 예시:
/*
const ws = new NotificationWebSocket('your-auth-token');
ws.connect();

// 특정 타입의 알림에 대한 핸들러 등록
ws.on('comment', notification => {
    console.log('New comment:', notification);
});

ws.on('version', notification => {
    console.log('New version:', notification);
});
*/ 