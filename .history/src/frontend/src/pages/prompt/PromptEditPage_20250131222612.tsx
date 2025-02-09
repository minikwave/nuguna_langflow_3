import React, { useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useDispatch, useSelector } from 'react-redux';
import { Container, CircularProgress, Alert } from '@mui/material';
import { PromptForm } from '../../components/prompt/PromptForm';
import { getPrompt } from '../../store/slices/promptSlice';
import { RootState, AppDispatch } from '../../store';

export const PromptEditPage: React.FC = () => {
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

    if (!prompt) {
        return (
            <Container maxWidth="lg">
                <Alert severity="info">프롬프트를 찾을 수 없습니다.</Alert>
            </Container>
        );
    }

    if (user?.id !== prompt.owner.id) {
        navigate(`/prompts/${id}`);
        return null;
    }

    const initialData = {
        title: prompt.title,
        description: prompt.description,
        content: prompt.latest_version?.content || '',
        expected_sql: prompt.latest_version?.expected_sql || '',
        tags: prompt.tags,
    };

    return (
        <Container maxWidth="lg">
            <PromptForm
                initialData={initialData}
                isEdit={true}
                promptId={Number(id)}
            />
        </Container>
    );
}; 