import React, { useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { useParams, useNavigate } from 'react-router-dom';
import {
    Box,
    Typography,
    Chip,
    Button,
    Paper,
    Divider,
    CircularProgress,
    Alert,
} from '@mui/material';
import { getPrompt } from '../../store/slices/promptSlice';
import { RootState, AppDispatch } from '../../store';
import { formatDistanceToNow } from 'date-fns';
import { ko } from 'date-fns/locale';

export const PromptDetail: React.FC = () => {
    const { id } = useParams<{ id: string }>();
    const dispatch = useDispatch<AppDispatch>();
    const navigate = useNavigate();
    const { currentPrompt: prompt, loading, error } = useSelector(
        (state: RootState) => state.prompt
    );
    const { user } = useSelector((state: RootState) => state.auth);

    useEffect(() => {
        if (id) {
            dispatch(getPrompt(Number(id)));
        }
    }, [dispatch, id]);

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

    if (!prompt) {
        return <Alert severity="info">프롬프트를 찾을 수 없습니다.</Alert>;
    }

    const isOwner = user?.id === prompt.owner.id;

    return (
        <Box sx={{ p: 3 }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
                <Box>
                    <Typography variant="h4" component="h1" gutterBottom>
                        {prompt.title}
                    </Typography>
                    <Box sx={{ mb: 2 }}>
                        {prompt.tags.map((tag) => (
                            <Chip
                                key={tag}
                                label={tag}
                                size="small"
                                sx={{ mr: 0.5 }}
                            />
                        ))}
                    </Box>
                    <Typography variant="body2" color="text.secondary">
                        작성자: {prompt.owner.username} ·{' '}
                        {formatDistanceToNow(new Date(prompt.created_at), {
                            addSuffix: true,
                            locale: ko,
                        })}
                    </Typography>
                </Box>
                {isOwner && (
                    <Button
                        variant="outlined"
                        onClick={() => navigate(`/prompts/${prompt.id}/edit`)}
                    >
                        수정
                    </Button>
                )}
            </Box>

            <Paper sx={{ p: 3, mb: 3 }}>
                <Typography variant="body1" paragraph>
                    {prompt.description}
                </Typography>
            </Paper>

            <Typography variant="h6" gutterBottom>
                최신 버전
            </Typography>
            {prompt.latest_version ? (
                <Paper sx={{ p: 3 }}>
                    <Box sx={{ mb: 2 }}>
                        <Typography variant="body2" color="text.secondary">
                            버전 {prompt.latest_version.number} ·{' '}
                            {formatDistanceToNow(
                                new Date(prompt.latest_version.created_at),
                                {
                                    addSuffix: true,
                                    locale: ko,
                                }
                            )}
                        </Typography>
                    </Box>
                    <Typography
                        variant="body1"
                        component="pre"
                        sx={{
                            whiteSpace: 'pre-wrap',
                            wordBreak: 'break-word',
                            fontFamily: 'monospace',
                            backgroundColor: 'grey.100',
                            p: 2,
                            borderRadius: 1,
                        }}
                    >
                        {prompt.latest_version.content}
                    </Typography>
                    {prompt.latest_version.expected_sql && (
                        <>
                            <Divider sx={{ my: 2 }} />
                            <Typography variant="subtitle2" gutterBottom>
                                예상 SQL
                            </Typography>
                            <Typography
                                variant="body1"
                                component="pre"
                                sx={{
                                    whiteSpace: 'pre-wrap',
                                    wordBreak: 'break-word',
                                    fontFamily: 'monospace',
                                    backgroundColor: 'grey.100',
                                    p: 2,
                                    borderRadius: 1,
                                }}
                            >
                                {prompt.latest_version.expected_sql}
                            </Typography>
                        </>
                    )}
                    <Box sx={{ mt: 2 }}>
                        <Typography variant="subtitle2" gutterBottom>
                            성능 지표
                        </Typography>
                        <Box
                            sx={{
                                display: 'flex',
                                gap: 3,
                            }}
                        >
                            <Typography variant="body2">
                                정확도: {prompt.latest_version.metrics.accuracy}%
                            </Typography>
                            <Typography variant="body2">
                                실행 시간: {prompt.latest_version.metrics.execution_time}ms
                            </Typography>
                            <Typography variant="body2">
                                성공률: {prompt.latest_version.metrics.success_rate}%
                            </Typography>
                        </Box>
                    </Box>
                </Paper>
            ) : (
                <Alert severity="info">아직 버전이 없습니다.</Alert>
            )}
        </Box>
    );
}; 