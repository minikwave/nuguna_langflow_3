import React from 'react';
import { Container } from '@mui/material';
import { TeamForm } from '../../components/team/TeamForm';

export const TeamCreatePage: React.FC = () => {
    return (
        <Container maxWidth="lg">
            <TeamForm />
        </Container>
    );
}; 