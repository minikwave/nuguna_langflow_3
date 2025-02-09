import React, { useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import {
    List,
    ListItem,
    ListItemText,
    ListItemIcon,
    Typography,
    IconButton,
    CircularProgress,
    Alert,
    Box,
} from '@mui/material';
import {
    Comment as CommentIcon,
    NewReleases as NewReleasesIcon,
    Person as PersonIcon,
    Group as GroupIcon,
    CheckCircle as CheckCircleIcon,
} from '@mui/icons-material';
import { getNotifications, markAsRead } from '../../store/slices/notificationSlice';
import { RootState, AppDispatch } from '../../store';
import { formatDistanceToNow } from 'date-fns';
import { ko } from 'date-fns/locale';
import { NotificationState } from '../../store/types';

const getNotificationIcon = (type: string) => {
    switch (type) {
        case 'comment':
            return <CommentIcon />;
        case 'version':
            return <NewReleasesIcon />;
        case 'mention':
            return <PersonIcon />;
        case 'team_invite':
            return <GroupIcon />;
        default:
            return <CommentIcon />;
    }
};

export const NotificationList: React.FC = () => {
    const dispatch = useDispatch<AppDispatch>();
    const { notifications, loading, error } = useSelector<RootState, NotificationState>(
        (state) => state.notification
    );

    useEffect(() => {
        dispatch(getNotifications());
    }, [dispatch]);

    const handleMarkAsRead = (id: number) => {
        dispatch(markAsRead(id));
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

    if (notifications.length === 0) {
        return (
            <Box sx={{ p: 3, textAlign: 'center' }}>
                <Typography color="text.secondary">
                    새로운 알림이 없습니다.
                </Typography>
            </Box>
        );
    }

    return (
        <List>
            {notifications.map((notification) => (
                <ListItem
                    key={notification.id}
                    sx={{
                        bgcolor: notification.is_read ? 'transparent' : 'action.hover',
                    }}
                    secondaryAction={
                        !notification.is_read && (
                            <IconButton
                                edge="end"
                                onClick={() => handleMarkAsRead(notification.id)}
                            >
                                <CheckCircleIcon />
                            </IconButton>
                        )
                    }
                >
                    <ListItemIcon>{getNotificationIcon(notification.type)}</ListItemIcon>
                    <ListItemText
                        primary={notification.content}
                        secondary={formatDistanceToNow(new Date(notification.created_at), {
                            addSuffix: true,
                            locale: ko,
                        })}
                    />
                </ListItem>
            ))}
        </List>
    );
}; 