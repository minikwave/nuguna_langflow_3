import React from 'react';
import { Container } from '@mui/material';
import { TeamDetail } from '../../components/team/TeamDetail';

export const TeamDetailPage: React.FC = () => {
    return (
        <Container maxWidth="lg">
            <TeamDetail />
        </Container>
    );
}; 