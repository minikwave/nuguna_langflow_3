import React from 'react';
import { useForm } from 'react-hook-form';
import { useDispatch, useSelector } from 'react-redux';
import { useNavigate } from 'react-router-dom';
import {
    Box,
    TextField,
    Button,
    Typography,
    Paper,
    Alert,
} from '@mui/material';
import { createTeam } from '../../store/slices/teamSlice';
import { RootState, AppDispatch } from '../../store';
import { TeamState } from '../../store/types';

interface TeamFormData {
    name: string;
    description?: string;
}

interface TeamFormProps {
    initialData?: TeamFormData;
    isEdit?: boolean;
    teamId?: number;
}

export const TeamForm: React.FC<TeamFormProps> = ({
    initialData,
    isEdit = false,
    teamId,
}) => {
    const {
        register,
        handleSubmit,
        formState: { errors },
    } = useForm<TeamFormData>({
        defaultValues: initialData || {
            name: '',
            description: '',
        },
    });

    const dispatch = useDispatch<AppDispatch>();
    const navigate = useNavigate();
    const { loading, error } = useSelector<RootState, TeamState>(
        (state) => state.team
    );

    const onSubmit = async (data: TeamFormData) => {
        const result = await dispatch(createTeam(data));
        if (createTeam.fulfilled.match(result)) {
            navigate('/teams');
        }
    };

    return (
        <Box component={Paper} sx={{ p: 3 }}>
            <Typography variant="h5" component="h1" gutterBottom>
                {isEdit ? '팀 수정' : '새 팀 생성'}
            </Typography>

            {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

            <Box
                component="form"
                onSubmit={handleSubmit(onSubmit)}
                sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}
            >
                <TextField
                    label="팀 이름"
                    {...register('name', {
                        required: '팀 이름을 입력해주세요',
                        minLength: {
                            value: 2,
                            message: '팀 이름은 최소 2자 이상이어야 합니다',
                        },
                    })}
                    error={!!errors.name}
                    helperText={errors.name?.message}
                    fullWidth
                />

                <TextField
                    label="설명 (선택사항)"
                    multiline
                    rows={3}
                    {...register('description')}
                    error={!!errors.description}
                    helperText={errors.description?.message}
                    fullWidth
                />

                <Box sx={{ display: 'flex', gap: 2, justifyContent: 'flex-end' }}>
                    <Button
                        type="button"
                        onClick={() => navigate(-1)}
                        disabled={loading}
                    >
                        취소
                    </Button>
                    <Button
                        type="submit"
                        variant="contained"
                        color="primary"
                        disabled={loading}
                    >
                        {loading
                            ? isEdit
                                ? '수정 중...'
                                : '생성 중...'
                            : isEdit
                            ? '수정'
                            : '생성'}
                    </Button>
                </Box>
            </Box>
        </Box>
    );
}; 