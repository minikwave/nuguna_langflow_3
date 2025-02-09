import React from 'react';
import { Container, Paper } from '@mui/material';
import { LoginForm } from '../../components/auth/LoginForm';

export const LoginPage: React.FC = () => {
    return (
        <Container maxWidth="sm">
            <Paper elevation={3} sx={{ mt: 8 }}>
                <LoginForm />
            </Paper>
        </Container>
    );
}; 