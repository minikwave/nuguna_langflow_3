export const config = {
  API_URL: process.env.REACT_APP_API_URL || 'http://localhost:5000',
  WS_URL: process.env.REACT_APP_WS_URL || 'ws://localhost:5000/ws',
  LANGFLOW_URL: process.env.REACT_APP_LANGFLOW_URL || 'http://localhost:7860'
}; 