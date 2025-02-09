import React, { useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useDispatch, useSelector } from 'react-redux';
import { Container, CircularProgress, Alert } from '@mui/material';
import { TeamForm } from '../../components/team/TeamForm';
import { getTeam } from '../../store/slices/teamSlice';
import { RootState, AppDispatch } from '../../store';
import { TeamState } from '../../store/types';

export const TeamEditPage: React.FC = () => {
    const { id } = useParams<{ id: string }>();
    const dispatch = useDispatch<AppDispatch>();
    const navigate = useNavigate();
    const { currentTeam: team, loading, error } = useSelector<RootState, TeamState>(
        (state) => state.team
    );
    const { user } = useSelector((state: RootState) => state.auth);

    useEffect(() => {
        if (id) {
            dispatch(getTeam(Number(id)));
        }
    }, [dispatch, id]);

    if (loading) {
        return (
            <Container
                maxWidth="lg"
                sx={{ display: 'flex', justifyContent: 'center', p: 3 }}
            >
                <CircularProgress />
            </Container>
        );
    }

    if (error) {
        return (
            <Container maxWidth="lg">
                <Alert severity="error">{error}</Alert>
            </Container>
        );
    }

    if (!team) {
        return (
            <Container maxWidth="lg">
                <Alert severity="info">팀을 찾을 수 없습니다.</Alert>
            </Container>
        );
    }

    const isAdmin = team.members.find((m) => m.user.id === user?.id)?.role === 'admin';
    if (!isAdmin) {
        navigate(`/teams/${id}`);
        return null;
    }

    const initialData = {
        name: team.name,
        description: team.description,
    };

    return (
        <Container maxWidth="lg">
            <TeamForm
                initialData={initialData}
                isEdit={true}
                teamId={Number(id)}
            />
        </Container>
    );
}; 