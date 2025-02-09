import React from 'react';
import { useForm, Controller } from 'react-hook-form';
import { useDispatch, useSelector } from 'react-redux';
import { useNavigate } from 'react-router-dom';
import {
    Box,
    TextField,
    Button,
    Typography,
    Paper,
    Alert,
    Autocomplete,
    Chip,
} from '@mui/material';
import { createPrompt, updatePrompt } from '../../store/slices/promptSlice';
import { RootState, AppDispatch } from '../../store';

interface PromptFormData {
    title: string;
    description: string;
    content: string;
    expected_sql?: string;
    tags: string[];
    team_id?: number;
}

interface PromptFormProps {
    initialData?: PromptFormData;
    isEdit?: boolean;
    promptId?: number;
}

export const PromptForm: React.FC<PromptFormProps> = ({
    initialData,
    isEdit = false,
    promptId,
}) => {
    const {
        control,
        register,
        handleSubmit,
        formState: { errors },
    } = useForm<PromptFormData>({
        defaultValues: initialData || {
            title: '',
            description: '',
            content: '',
            expected_sql: '',
            tags: [],
        },
    });

    const dispatch = useDispatch<AppDispatch>();
    const navigate = useNavigate();
    const { loading, error } = useSelector((state: RootState) => state.prompt);

    const onSubmit = async (data: PromptFormData) => {
        const result = isEdit
            ? await dispatch(
                  updatePrompt({
                      id: promptId!,
                      content: data.content,
                      expected_sql: data.expected_sql,
                  })
              )
            : await dispatch(createPrompt(data));

        if (
            (isEdit && updatePrompt.fulfilled.match(result)) ||
            (!isEdit && createPrompt.fulfilled.match(result))
        ) {
            navigate(isEdit ? `/prompts/${promptId}` : '/prompts');
        }
    };

    return (
        <Box component={Paper} sx={{ p: 3 }}>
            <Typography variant="h5" component="h1" gutterBottom>
                {isEdit ? '프롬프트 수정' : '새 프롬프트 작성'}
            </Typography>

            {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

            <Box
                component="form"
                onSubmit={handleSubmit(onSubmit)}
                sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}
            >
                {!isEdit && (
                    <>
                        <TextField
                            label="제목"
                            {...register('title', {
                                required: '제목을 입력해주세요',
                                minLength: {
                                    value: 3,
                                    message: '제목은 최소 3자 이상이어야 합니다',
                                },
                            })}
                            error={!!errors.title}
                            helperText={errors.title?.message}
                            fullWidth
                        />

                        <TextField
                            label="설명"
                            multiline
                            rows={3}
                            {...register('description', {
                                required: '설명을 입력해주세요',
                                minLength: {
                                    value: 10,
                                    message: '설명은 최소 10자 이상이어야 합니다',
                                },
                            })}
                            error={!!errors.description}
                            helperText={errors.description?.message}
                            fullWidth
                        />

                        <Controller
                            name="tags"
                            control={control}
                            render={({ field: { onChange, value } }) => (
                                <Autocomplete
                                    multiple
                                    freeSolo
                                    options={[]}
                                    value={value}
                                    onChange={(_, newValue) => onChange(newValue)}
                                    renderTags={(value, getTagProps) =>
                                        value.map((option, index) => (
                                            <Chip
                                                label={option}
                                                {...getTagProps({ index })}
                                                key={option}
                                            />
                                        ))
                                    }
                                    renderInput={(params) => (
                                        <TextField
                                            {...params}
                                            label="태그"
                                            placeholder="Enter를 눌러 태그 추가"
                                        />
                                    )}
                                />
                            )}
                        />
                    </>
                )}

                <TextField
                    label="프롬프트 내용"
                    multiline
                    rows={5}
                    {...register('content', {
                        required: '프롬프트 내용을 입력해주세요',
                    })}
                    error={!!errors.content}
                    helperText={errors.content?.message}
                    fullWidth
                />

                <TextField
                    label="예상 SQL (선택사항)"
                    multiline
                    rows={3}
                    {...register('expected_sql')}
                    error={!!errors.expected_sql}
                    helperText={errors.expected_sql?.message}
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