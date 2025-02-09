import React from 'react';
import { Container } from '@mui/material';
import { TeamList } from '../../components/team/TeamList';

export const TeamListPage: React.FC = () => {
    return (
        <Container maxWidth="lg">
            <TeamList />
        </Container>
    );
}; 