import React, { useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { useNavigate } from 'react-router-dom';
import {
    Box,
    Card,
    CardContent,
    Typography,
    Chip,
    Button,
    Grid,
    CircularProgress,
    Alert,
} from '@mui/material';
import { getPrompts } from '../../store/slices/promptSlice';
import { RootState, AppDispatch } from '../../store';
import { formatDistanceToNow } from 'date-fns';
import { ko } from 'date-fns/locale';

export const PromptList: React.FC = () => {
    const dispatch = useDispatch<AppDispatch>();
    const navigate = useNavigate();
    const { prompts, loading, error } = useSelector((state: RootState) => state.prompt);

    useEffect(() => {
        dispatch(getPrompts());
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
                    프롬프트 목록
                </Typography>
                <Button
                    variant="contained"
                    color="primary"
                    onClick={() => navigate('/prompts/new')}
                >
                    새 프롬프트 작성
                </Button>
            </Box>

            <Grid container spacing={3}>
                {prompts.map((prompt) => (
                    <Grid item xs={12} sm={6} md={4} key={prompt.id}>
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
                            onClick={() => navigate(`/prompts/${prompt.id}`)}
                        >
                            <CardContent sx={{ flexGrow: 1 }}>
                                <Typography variant="h6" component="h3" gutterBottom>
                                    {prompt.title}
                                </Typography>
                                <Typography
                                    variant="body2"
                                    color="text.secondary"
                                    sx={{
                                        mb: 2,
                                        display: '-webkit-box',
                                        WebkitLineClamp: 3,
                                        WebkitBoxOrient: 'vertical',
                                        overflow: 'hidden',
                                    }}
                                >
                                    {prompt.description}
                                </Typography>
                                <Box sx={{ mb: 2 }}>
                                    {prompt.tags.map((tag) => (
                                        <Chip
                                            key={tag}
                                            label={tag}
                                            size="small"
                                            sx={{ mr: 0.5, mb: 0.5 }}
                                        />
                                    ))}
                                </Box>
                                <Box
                                    sx={{
                                        display: 'flex',
                                        justifyContent: 'space-between',
                                        alignItems: 'center',
                                    }}
                                >
                                    <Typography variant="body2" color="text.secondary">
                                        {prompt.owner.username}
                                    </Typography>
                                    <Typography variant="body2" color="text.secondary">
                                        {formatDistanceToNow(new Date(prompt.created_at), {
                                            addSuffix: true,
                                            locale: ko,
                                        })}
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