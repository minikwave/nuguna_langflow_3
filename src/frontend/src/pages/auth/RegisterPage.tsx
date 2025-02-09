import React from 'react';
import { Container, Paper } from '@mui/material';
import { RegisterForm } from '../../components/auth/RegisterForm';

export const RegisterPage: React.FC = () => {
    return (
        <Container maxWidth="sm">
            <Paper elevation={3} sx={{ mt: 8 }}>
                <RegisterForm />
            </Paper>
        </Container>
    );
}; 