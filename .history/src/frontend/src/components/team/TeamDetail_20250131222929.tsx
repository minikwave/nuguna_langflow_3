import React, { useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { useParams, useNavigate } from 'react-router-dom';
import {
    Box,
    Typography,
    Button,
    Paper,
    List,
    ListItem,
    ListItemText,
    ListItemSecondaryAction,
    IconButton,
    CircularProgress,
    Alert,
    Chip,
    Dialog,
    DialogTitle,
    DialogContent,
    DialogActions,
    TextField,
} from '@mui/material';
import {
    Edit as EditIcon,
    Delete as DeleteIcon,
    PersonAdd as PersonAddIcon,
} from '@mui/icons-material';
import { getTeam, inviteToTeam } from '../../store/slices/teamSlice';
import { RootState, AppDispatch } from '../../store';
import { formatDistanceToNow } from 'date-fns';
import { ko } from 'date-fns/locale';
import { TeamState } from '../../store/types';
import { useForm } from 'react-hook-form';

interface InviteFormData {
    email: string;
    role: 'admin' | 'member' | 'viewer';
}

export const TeamDetail: React.FC = () => {
    const { id } = useParams<{ id: string }>();
    const dispatch = useDispatch<AppDispatch>();
    const navigate = useNavigate();
    const { currentTeam: team, loading, error } = useSelector<RootState, TeamState>(
        (state) => state.team
    );
    const { user } = useSelector((state: RootState) => state.auth);
    const [inviteDialogOpen, setInviteDialogOpen] = React.useState(false);

    const {
        register,
        handleSubmit,
        formState: { errors },
        reset,
    } = useForm<InviteFormData>({
        defaultValues: {
            role: 'member',
        },
    });

    useEffect(() => {
        if (id) {
            dispatch(getTeam(Number(id)));
        }
    }, [dispatch, id]);

    const handleInvite = async (data: InviteFormData) => {
        if (id) {
            const result = await dispatch(
                inviteToTeam({
                    teamId: Number(id),
                    ...data,
                })
            );
            if (inviteToTeam.fulfilled.match(result)) {
                setInviteDialogOpen(false);
                reset();
            }
        }
    };

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

    if (!team) {
        return <Alert severity="info">팀을 찾을 수 없습니다.</Alert>;
    }

    const isAdmin = team.members.find((m) => m.user.id === user?.id)?.role === 'admin';

    return (
        <Box sx={{ p: 3 }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
                <Box>
                    <Typography variant="h4" component="h1" gutterBottom>
                        {team.name}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                        생성일:{' '}
                        {formatDistanceToNow(new Date(team.created_at), {
                            addSuffix: true,
                            locale: ko,
                        })}
                    </Typography>
                </Box>
                {isAdmin && (
                    <Box>
                        <Button
                            startIcon={<EditIcon />}
                            onClick={() => navigate(`/teams/${team.id}/edit`)}
                            sx={{ mr: 1 }}
                        >
                            수정
                        </Button>
                        <Button
                            startIcon={<PersonAddIcon />}
                            onClick={() => setInviteDialogOpen(true)}
                            variant="contained"
                        >
                            초대
                        </Button>
                    </Box>
                )}
            </Box>

            {team.description && (
                <Paper sx={{ p: 3, mb: 3 }}>
                    <Typography variant="body1">{team.description}</Typography>
                </Paper>
            )}

            <Typography variant="h6" gutterBottom sx={{ mt: 4 }}>
                팀원 목록
            </Typography>
            <Paper>
                <List>
                    {team.members.map((member) => (
                        <ListItem key={member.id}>
                            <ListItemText
                                primary={member.user.username}
                                secondary={`가입일: ${formatDistanceToNow(
                                    new Date(member.joined_at),
                                    { addSuffix: true, locale: ko }
                                )}`}
                            />
                            <ListItemSecondaryAction>
                                <Chip
                                    label={member.role}
                                    color={member.role === 'admin' ? 'primary' : 'default'}
                                    size="small"
                                />
                            </ListItemSecondaryAction>
                        </ListItem>
                    ))}
                </List>
            </Paper>

            <Dialog
                open={inviteDialogOpen}
                onClose={() => setInviteDialogOpen(false)}
                maxWidth="sm"
                fullWidth
            >
                <form onSubmit={handleSubmit(handleInvite)}>
                    <DialogTitle>팀원 초대</DialogTitle>
                    <DialogContent>
                        <Box sx={{ pt: 1, display: 'flex', flexDirection: 'column', gap: 2 }}>
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
                                select
                                label="역할"
                                {...register('role')}
                                SelectProps={{
                                    native: true,
                                }}
                                fullWidth
                            >
                                <option value="admin">관리자</option>
                                <option value="member">멤버</option>
                                <option value="viewer">뷰어</option>
                            </TextField>
                        </Box>
                    </DialogContent>
                    <DialogActions>
                        <Button onClick={() => setInviteDialogOpen(false)}>취소</Button>
                        <Button type="submit" variant="contained">
                            초대
                        </Button>
                    </DialogActions>
                </form>
            </Dialog>
        </Box>
    );
}; 