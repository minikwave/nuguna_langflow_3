import React from 'react';
import { useForm } from 'react-hook-form';
import { useNavigate } from 'react-router-dom';
import { useDispatch, useSelector } from 'react-redux';
import {
    Box,
    TextField,
    Button,
    Typography,
    Link,
    Alert,
} from '@mui/material';
import { register as registerUser } from '../../store/slices/authSlice';
import { RootState, AppDispatch } from '../../store';

interface RegisterFormData {
    email: string;
    username: string;
    password: string;
    confirmPassword: string;
    full_name?: string;
}

export const RegisterForm: React.FC = () => {
    const {
        register,
        handleSubmit,
        watch,
        formState: { errors },
    } = useForm<RegisterFormData>();
    const navigate = useNavigate();
    const dispatch = useDispatch<AppDispatch>();
    const { loading, error } = useSelector((state: RootState) => state.auth);

    const onSubmit = async (data: RegisterFormData) => {
        const { confirmPassword, ...registerData } = data;
        const result = await dispatch(registerUser(registerData));
        if (registerUser.fulfilled.match(result)) {
            navigate('/');
        }
    };

    return (
        <Box
            component="form"
            onSubmit={handleSubmit(onSubmit)}
            sx={{
                display: 'flex',
                flexDirection: 'column',
                gap: 2,
                maxWidth: 400,
                mx: 'auto',
                p: 3,
            }}
        >
            <Typography variant="h5" component="h1" align="center" gutterBottom>
                회원가입
            </Typography>

            {error && <Alert severity="error">{error}</Alert>}

            <TextField
                label="이메일"
                type="email"
                {...register('email', {
                    required: '이메일을 입력해주세요',
                    pattern: {
                        value: /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i,
                        message: '유효한 이메일 주소를 입력해주세요',
                    },
                })}
                error={!!errors.email}
                helperText={errors.email?.message}
                fullWidth
            />

            <TextField
                label="사용자 이름"
                {...register('username', {
                    required: '사용자 이름을 입력해주세요',
                    minLength: {
                        value: 3,
                        message: '사용자 이름은 최소 3자 이상이어야 합니다',
                    },
                })}
                error={!!errors.username}
                helperText={errors.username?.message}
                fullWidth
            />

            <TextField
                label="이름 (선택사항)"
                {...register('full_name')}
                fullWidth
            />

            <TextField
                label="비밀번호"
                type="password"
                {...register('password', {
                    required: '비밀번호를 입력해주세요',
                    minLength: {
                        value: 8,
                        message: '비밀번호는 최소 8자 이상이어야 합니다',
                    },
                })}
                error={!!errors.password}
                helperText={errors.password?.message}
                fullWidth
            />

            <TextField
                label="비밀번호 확인"
                type="password"
                {...register('confirmPassword', {
                    required: '비밀번호를 다시 입력해주세요',
                    validate: (value) =>
                        value === watch('password') || '비밀번호가 일치하지 않습니다',
                })}
                error={!!errors.confirmPassword}
                helperText={errors.confirmPassword?.message}
                fullWidth
            />

            <Button
                type="submit"
                variant="contained"
                color="primary"
                disabled={loading}
                fullWidth
            >
                {loading ? '가입 중...' : '회원가입'}
            </Button>

            <Box sx={{ textAlign: 'center' }}>
                <Link
                    component="button"
                    variant="body2"
                    onClick={() => navigate('/login')}
                >
                    이미 계정이 있으신가요? 로그인
                </Link>
            </Box>
        </Box>
    );
}; 