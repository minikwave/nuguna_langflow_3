import React from 'react';
import { Container } from '@mui/material';
import { PromptList } from '../../components/prompt/PromptList';

export const PromptListPage: React.FC = () => {
    return (
        <Container maxWidth="lg">
            <PromptList />
        </Container>
    );
}; 