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
import { login } from '../../store/slices/authSlice';
import { RootState, AppDispatch } from '../../store';

interface LoginFormData {
    email: string;
    password: string;
}

export const LoginForm: React.FC = () => {
    const {
        register,
        handleSubmit,
        formState: { errors },
    } = useForm<LoginFormData>();
    const navigate = useNavigate();
    const dispatch = useDispatch<AppDispatch>();
    const { loading, error } = useSelector((state: RootState) => state.auth);

    const onSubmit = async (data: LoginFormData) => {
        const result = await dispatch(login(data));
        if (login.fulfilled.match(result)) {
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
                로그인
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

            <Button
                type="submit"
                variant="contained"
                color="primary"
                disabled={loading}
                fullWidth
            >
                {loading ? '로그인 중...' : '로그인'}
            </Button>

            <Box sx={{ textAlign: 'center' }}>
                <Link
                    component="button"
                    variant="body2"
                    onClick={() => navigate('/register')}
                >
                    계정이 없으신가요? 회원가입
                </Link>
            </Box>
        </Box>
    );
}; 