import React from 'react';
import { Container } from '@mui/material';
import { PromptForm } from '../../components/prompt/PromptForm';

export const PromptCreatePage: React.FC = () => {
    return (
        <Container maxWidth="lg">
            <PromptForm />
        </Container>
    );
}; 