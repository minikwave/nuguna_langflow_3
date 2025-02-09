import React, { useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { useNavigate } from 'react-router-dom';
import {
    Box,
    Card,
    CardContent,
    Typography,
    Button,
    Grid,
    CircularProgress,
    Alert,
    Chip,
} from '@mui/material';
import { getTeams } from '../../store/slices/teamSlice';
import { RootState, AppDispatch } from '../../store';
import { formatDistanceToNow } from 'date-fns';
import { ko } from 'date-fns/locale';
import { TeamState } from '../../store/types';

export const TeamList: React.FC = () => {
    const dispatch = useDispatch<AppDispatch>();
    const navigate = useNavigate();
    const { teams, loading, error } = useSelector<RootState, TeamState>(
        (state) => state.team
    );

    useEffect(() => {
        dispatch(getTeams()); // 모든 팀을 가져오도록 변경
    }, [dispatch]);

    if (loading) {
        return (
            <Box sx={{ display: 'flex', justifyContent: 'center', p: 3 }}>
                <CircularProgress />
            </Box>
        );
    }

    if (error) {
        return <Alert severity="error">{error}</Alert>;
    }

    return (
        <Box sx={{ p: 3 }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
                <Typography variant="h5" component="h2">
                    팀 목록
                </Typography>
                <Button
                    variant="contained"
                    color="primary"
                    onClick={() => navigate('/teams/new')}
                >
                    새 팀 생성
                </Button>
            </Box>

            <Grid container spacing={3}>
                {teams.map((team) => (
                    <Grid item xs={12} sm={6} md={4} key={team.id}>
                        <Card
                            sx={{
                                height: '100%',
                                display: 'flex',
                                flexDirection: 'column',
                                cursor: 'pointer',
                                '&:hover': {
                                    boxShadow: 6,
                                },
                            }}
                            onClick={() => navigate(`/teams/${team.id}`)}
                        >
                            <CardContent sx={{ flexGrow: 1 }}>
                                <Typography variant="h6" component="h3" gutterBottom>
                                    {team.name}
                                </Typography>
                                {team.description && (
                                    <Typography
                                        variant="body2"
                                        color="text.secondary"
                                        sx={{
                                            mb: 2,
                                            display: '-webkit-box',
                                            WebkitLineClamp: 2,
                                            WebkitBoxOrient: 'vertical',
                                            overflow: 'hidden',
                                        }}
                                    >
                                        {team.description}
                                    </Typography>
                                )}
                                <Box sx={{ mb: 2 }}>
                                    <Typography variant="body2" color="text.secondary">
                                        멤버: {team.members?.length || 0}명
                                    </Typography>
                                </Box>
                                <Box
                                    sx={{
                                        display: 'flex',
                                        justifyContent: 'space-between',
                                        alignItems: 'center',
                                    }}
                                >
                                    <Chip
                                        label={`내 역할: ${team.members?.find(
                                            (m) => m.user?.id === 1
                                        )?.role || '멤버'}`}
                                        size="small"
                                    />
                                    <Typography variant="body2" color="text.secondary">
                                        {team.created_at
                                            ? formatDistanceToNow(new Date(team.created_at), {
                                                  addSuffix: true,
                                                  locale: ko,
                                              })
                                            : '시간 정보 없음'}
                                    </Typography>
                                </Box>
                            </CardContent>
                        </Card>
                    </Grid>
                ))}
            </Grid>
        </Box>
    );
};
