import React from 'react';
import { Container } from '@mui/material';
import { PromptDetail } from '../../components/prompt/PromptDetail';

export const PromptDetailPage: React.FC = () => {
    return (
        <Container maxWidth="lg">
            <PromptDetail />
        </Container>
    );
}; 